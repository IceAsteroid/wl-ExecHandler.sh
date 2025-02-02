#!/bin/bash

### Simple program runner & supervior mainly for window managers that runs programs in exec in a WM's conf ###

# Exit immediately if a command returns non-zero exit status code
set -e
# Exit & Return error if referencing to an unset variable.
set -u

declare -gi CurrentScriptPgid
declare TmpDir

# Kill all sub processes when the script is sent to exit
CurrentScriptPgid="$(ps -o pgid= $$ | grep -o '[0-9]*')"
trap "trap - SIGTERM && kill -- -${CurrentScriptPgid}" SIGHUP SIGINT SIGTERM EXIT

TmpDir="/tmp"

printHelp_() {
  cat <<EOF
Usage:
  $(basename "$0") [OPTIONS]
Options:
  -r              Restart the command.
  -k              Keep the existing running command.
  -R              Revive the command if it crashes.
  -c COMMAND      Specify the main command.
  -w COMMANDS     Whole line of commands to run.
  -h              Show this help message.
Description:
  Restart or keep COMMAND running based on options.
  Use only one of -r or -k.
  Both -c and -w options must be specified.
  Note:
    This script removes the BG '&' symbol if presented, which forces COMMAND
    , to run in forground.
  Example:
    $(basename "$0") -c "emacs -nw" -w "[ -f emacsExist ] && _COMMAND_ && notify-send 'Emacs started'"
EOF
}

function testArgs_() {
  # Test if any of the mandatory options are not specified.
  declare -A optsMustArray
  declare -i isOptionMissing
  optsMustArray=(
    ["IsRestart"]="-r Or -k"
    # ["IsRevive"]="-R"
    ["MainCmdLine"]="-c"
    ["WholeCmdLine"]="-w"
  )
  for i in "${!optsMustArray[@]}"; do
    if ! [ -v "${i}" ]; then
      echo "#!Mandatory Option ${optsMustArray[$i]} Not Specified!"
      isOptionMissing=1
    fi
  done
  if ! [[ -v isOptionMissing ]]; then
    return 0
  elif (( "${isOptionMissing}" )); then
    exit 2
  fi
}

# Print usage info if zero arguments or first argument is not an option.
# Argumental options without arguments are handled by ‘*) printHelp_’ below.
if ! [[ -v 1 ]]; then
  printHelp_; exit 1
elif ! [[ "${1}" =~ -r|-k|-R|-c|-w|-a ]]; then
  printHelp_; exit 1
fi

while getopts :rkRc:w: OPT; do
  case "${OPT}" in
    r) declare -gi IsRestart=1;;
    k) declare -gi IsRestart=0;;
    R) declare -gi IsRevive=1;;
    c) declare -g MainCmdLine="${OPTARG}";;
    w) declare -g WholeCmdLine="${OPTARG}";;
    *) printHelp_; exit 1;;
  esac
done

testArgs_

function vGetMainCmdLineTrimmed_() {
  declare mainCmdLineTrimmed
  # Trim \t \s \n
  mainCmdLineTrimmed="$(echo -n "${MainCmdLine}" | awk '{$1=$1;print}' | tr -d '\n')"
  echo -n "${mainCmdLineTrimmed}"
}

function isBackgroundSignSpecified_() {
  declare mainCmdLineTrimmed
  declare -i isBackgroundSignSpecified
  mainCmdLineTrimmed="$(vGetMainCmdLineTrimmed_)"
  if grep --quiet ' &$' <<<"${mainCmdLineTrimmed}"; then
    isBackgroundSignSpecified="1"
  else
    isBackgroundSignSpecified="0"
  fi
  echo -n "${isBackgroundSignSpecified}"
}

function vGetMainCmdLineTrimmedNoBG_() {
  declare mainCmdLineTrimmed
  mainCmdLineTrimmed="$(vGetMainCmdLineTrimmed_)"
  echo -n "${mainCmdLineTrimmed/ &/}"
}

function vGetMainCmdLineTrimmedNoArgsNoBg_() {
  declare mainCmdLineTrimmedNoBg
  mainCmdLineTrimmedNoBg="$(vGetMainCmdLineTrimmedNoBG_)"
  awk -F' ' '{print $1}' <<<"${mainCmdLineTrimmedNoBg}"
}

function vGetArgsOfCmdLine_() {
  declare mainCmdLineTrimmedNoBg
  mainCmdLineTrimmedNoBg="$(vGetMainCmdLineTrimmedNoBG_)"
  # remove command and leave options, if no options specified, return empty
  sed 's|^ *[^ ]*||' <<<"${mainCmdLineTrimmedNoBg}"
}

function vFuseMainCmdLineTrimmedNoBgInWholeCmdLine_() {
  # trimmed, no bg &,
  declare mainCmdLineTrimmedNoBg mainCmdLineTrimmedNoArgsNoBg wholeCmdLine
  mainCmdLineTrimmedNoBg="$(vGetMainCmdLineTrimmedNoBG_)"
  mainCmdLineTrimmedNoArgsNoBg="$(vGetMainCmdLineTrimmedNoArgsNoBg_)"
  wholeCmdLine="${WholeCmdLine}"
  sed "s|_COMMAND_|${mainCmdLineTrimmedNoBg} \&>/tmp/swayExecHandler_${mainCmdLineTrimmedNoArgsNoBg}.log|" <<<"${wholeCmdLine}"
}

function vGetPidsOfMainCmd_() {
  declare mainCmdLineTrimmedNoArgsNoBg
  mainCmdLineTrimmedNoArgsNoBg="$(vGetMainCmdLineTrimmedNoArgsNoBg_)"
  # match exact full name with pidof
  pidof -x "${mainCmdLineTrimmedNoArgsNoBg}"
}

function vGetSameMainCmdLineItsLogFilePath_() {
  declare tmpDir mainCmdLineTrimmedNoArgsNoBg sameMainCmdLineItsLogFilePath
  tmpDir="${TmpDir}"
  mainCmdLineTrimmedNoArgsNoBg="$(vGetMainCmdLineTrimmedNoArgsNoBg_)"
  sameMainCmdLineItsLogFilePath="${tmpDir}/swayExecHandler_${mainCmdLineTrimmedNoArgsNoBg}.log"
  echo -n "${sameMainCmdLineItsLogFilePath}"
}

function vGetSameMainCmdLineItsPgidFilePath_() {
  declare tmpDir mainCmdLineTrimmedNoArgsNoBg sameMainCmdLineItsPgidFilePath
  tmpDir="${TmpDir}"
  mainCmdLineTrimmedNoArgsNoBg="$(vGetMainCmdLineTrimmedNoArgsNoBg_)"
  sameMainCmdLineItsPgidFilePath="${tmpDir}/swayExecHandler_${mainCmdLineTrimmedNoArgsNoBg}.pgid"
  echo -n "${sameMainCmdLineItsPgidFilePath}"
}

function aCreateIfNonExistentSameMainCmdLineItsPgidPath_() {
  declare tmpDir sameMainCmdLineItsPgidFilePath
  tmpDir="${TmpDir}"
  sameMainCmdLineItsPgidFilePath="$(vGetSameMainCmdLineItsPgidFilePath_)"
  # Might need to tweak for better permission
  [[ -d "${tmpDir}" ]] || { mkdir -P "${tmpDir}" && chmod 744 "${tmpDir}"; }
  [[ -f "${sameMainCmdLineItsPgidFilePath}" ]] \
    || { touch "${sameMainCmdLineItsPgidFilePath}" && chmod 744 "${sameMainCmdLineItsPgidFilePath}"; }
}

function vGetPrevSameMainCmdItsPgid_() {
  declare mainCmdLineTrimmedNoArgsNoBg sameMainCmdLineItsPgidFilePath
  declare -i prevSameMainCmdLineItsPgid
  mainCmdLineTrimmedNoArgsNoBg="$(vGetMainCmdLineTrimmedNoArgsNoBg_)"
  sameMainCmdLineItsPgidFilePath="$(vGetSameMainCmdLineItsPgidFilePath_)"
  # trim \t \s \n
  prevSameMainCmdLineItsPgid="$(cat "${sameMainCmdLineItsPgidFilePath}" | awk '{$1=$1;print}' | tr -d '\n')"
  echo -n "${prevSameMainCmdLineItsPgid}"
}

function aWriteCurrentPgidToMainCmdItsPgidFile_() {
  declare mainCmdLineTrimmedNoArgsNoBg sameMainCmdLineItsPgidFilePath
  declare -i currentShellPid
  mainCmdLineTrimmedNoArgsNoBg="$(vGetMainCmdLineTrimmedNoArgsNoBg_)"
  sameMainCmdLineItsPgidFilePath="$(vGetSameMainCmdLineItsPgidFilePath_)"
  # Shell pid can be directly accessed in a function
  currentShellPid="${CurrentScriptPgid}"
  echo -n "${currentShellPid}" > "${sameMainCmdLineItsPgidFilePath}"
}

function isPrevSameMainCmdLineRunning_() {
  declare -i prevSameMainCmdLineItsPgid isPrevSameMainCmdLineRunning
  prevSameMainCmdLineItsPgid="$(vGetPrevSameMainCmdItsPgid_)"
  # if ! [[ "${prevSameMainCmdLineItsPgid}" == "" ]]; then
  #   if ! [[ "${prevSameMainCmdLineItsPgid}" -eq 0 ]] ; then
  #     if pgrep -P "${prevSameMainCmdLineItsPgid}" 1>/dev/null ; then
  #       isPrevSameMainCmdLineRunning="1"
  #     else
  #       isPrevSameMainCmdLineRunning="0"
  #     fi
  #   fi
  # fi
  if ! [[ "${prevSameMainCmdLineItsPgid}" == "" ]] \
       && ! [[ "${prevSameMainCmdLineItsPgid}" -eq 0 ]] \
       && pgrep -P "${prevSameMainCmdLineItsPgid}" 1>/dev/null ; then
    isPrevSameMainCmdLineRunning="1"
  else
    isPrevSameMainCmdLineRunning="0"
  fi
  echo -n "${isPrevSameMainCmdLineRunning}"
}

function aKillPrevSameMainCmdItsPgidIfExist_() {
  declare -i isPrevSameMainCmdLineRunning prevSameMainCmdLineItsPgid
  isPrevSameMainCmdLineRunning="$(isPrevSameMainCmdLineRunning_)"
  prevSameMainCmdLineItsPgid="$(vGetPrevSameMainCmdItsPgid_)"
  # zero or empty indidates no previous MainCmdLine has run yet.
  if (( "${isPrevSameMainCmdLineRunning}" )); then
    pkill -P "${prevSameMainCmdLineItsPgid}"
  fi
}

function aRunWholeCmdLineReviveIfMainCmdLineCrash_() {
  declare fuseMainCmdLineTrimmedNoBgInWholeCmdLine
  declare -i isRevive mainCmdLineInRunPid
  [[ -v IsRevive ]] && isRevive="${IsRevive}" || isRevive="0"
  fuseMainCmdLineTrimmedNoBgInWholeCmdLine="$(vFuseMainCmdLineTrimmedNoBgInWholeCmdLine_)"
  if (( "${isRevive}" )); then
    eval "${fuseMainCmdLineTrimmedNoBgInWholeCmdLine}" &
    mainCmdLineInRunPid="$!"
    while sleep 2; do
      if ! ps -p "${mainCmdLineInRunPid}" 1>/dev/null; then
        eval "${fuseMainCmdLineTrimmedNoBgInWholeCmdLine}" &
        mainCmdLineInRunPid="$!"
      fi
    done
  else
    eval "${fuseMainCmdLineTrimmedNoBgInWholeCmdLine}"
  fi
}

function aMainStart_() {
  declare mainCmdLineTrimmedNoArgsNoBg
  declare -i prevSameMainCmdItsPgid isRestart isPrevSameMainCmdLineRunning
  mainCmdLineTrimmedNoArgsNoBg="$(vGetMainCmdLineTrimmedNoArgsNoBg_)"
  # prevSameMainCmdItsPgid="$(vGetPrevSameMainCmdItsPgid_)"
  isRestart="${IsRestart}"
  isPrevSameMainCmdLineRunning="$(isPrevSameMainCmdLineRunning_)"
  if (( "${isRestart}")); then
    if (( "${isPrevSameMainCmdLineRunning}" )); then
      echo "# Main command is running, now killed & restarted anyway."
    else
      echo "# Main command isn' running, now restarted anyway."
    fi
    # Must kill previous MainCmdLine before write current one to the pgid file
    aKillPrevSameMainCmdItsPgidIfExist_ \
      && aWriteCurrentPgidToMainCmdItsPgidFile_ \
      && aRunWholeCmdLineReviveIfMainCmdLineCrash_
  else
    if ! (( "${isPrevSameMainCmdLineRunning}" )); then
      echo "# Main command doesn't run yet, now started."
      aWriteCurrentPgidToMainCmdItsPgidFile_ \
        && aRunWholeCmdLineReviveIfMainCmdLineCrash_
    else
      echo "# Main command is already running."
    fi
  fi
}

aCreateIfNonExistentSameMainCmdLineItsPgidPath_

(( "$(isBackgroundSignSpecified_)" )) \
  && echo "# Background sign '&' specified. Has removed to run command in foreground."

aMainStart_
