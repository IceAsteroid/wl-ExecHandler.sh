# wl-ExecHandler.sh
Simple program runner & supervior mainly for window managers that runs programs in exec in a WM's conf

# Description & Motivation

Have you ever been tired of programs launched in a Window manager's conf file and then some of them crashed and you have to restart them manually?

Or, those leftovers still running in the background when the Window manager exits or crashes.

This script comes to rescue.

# Features
- Restarts the program if it's crashed with `-R` option.
- Prevent to run the program if it's already running with `-k` option.
  - By checking if a temp file that stores the pgid of the script that's running the same program.    
- Force to restart whether the program is running or not.
- Can be terminated of all programs launched by the script, and instances of script itself when the Window Manager exits
  - By using `killall -g wl-ExecHandler.sh` that terminates all processes of pgid of running instances of the script.

# Help page
```
Usage:
  swayExecHandlerNew.sh [OPTIONS]
Options:
  -r              Restart the command.
  -k              Keep the existing running command.
  -R              Revive the command if it crashes.
  -c COMMAND      Specify the main command.
  -w COMMANDS     Whole line of commands to run.
  -h              Show this help message.
  -v              Enable verbose logging.
Description:
  Restart or keep COMMAND running based on options.
  Use only one of -r or -k.
  Both -c and -w options must be specified.
  Note:
    This script removes the BG '&' symbol if presented, which forces COMMAND
    , to run in forground.
  Example:
    -c "emacs -nw" -w "[ -f emacsExist ] && _COMMAND_ && echo 'Emacs started'
```
