# wl-ExecHandler.sh
Simple program runner & supervior mainly for window managers that runs programs in exec in a WM's conf

# Description & Motivation

Have you ever been tired of programs launched in a Window manager's conf file and then some of them crash and you have to restart them manually?

Or, those leftovers still running in the background when the Window manager exits or crashes.

This script comes to rescue.

# Features
- Revives the program automatically if it's crashed with `-R` option.
- Prevents to run the program if it's already running with `-k` option.
  - By checking if a temp file that stores the pgid of the script that's running the same program.    
- Forces to restart whether the program is running or not with `-r` option.
- Can be terminated of all programs launched by the script, and instances of script itself when the Window Manager exits
  - By using `killall -g wl-ExecHandler.sh` that terminates all processes of pgid of running instances of the script.
  - For example in sway: `bindsym --no-repeat Control+Alt+Delete exec "killall -g wl-ExecHandler.sh && swaymsg exit"`
- Log the program's output to a file in the directory specified in `TmpDir` in the script, the name would be like `swayExecHandler_CommandName.log`.
  - The name hasn't been changed from `swayExecHandler_CommandName.log` to `wl-ExecHandler_CommandName.log`, yet.

# Help page
```
Usage:
  wl-ExecHandler.sh [OPTIONS]
Options:
  -r              Restart the running command.
  -k              Keep the existing running command.
  -R              Always revive the command if it crashes.
  -c COMMAND      Specify the main command.
  -w COMMANDS     Whole line of commands to run.
  -h              Show this help message.
Description:
  Restart or keep COMMAND running based on options.
  Use only one of -r or -k.
  Both -c and -w options must be specified.
Note:
  The -r option restarts the command if running, otherwise just start it.
  The -k option doesn't run the command if running, otherwise just start it.
  This script removes the BG '&' symbol if presented, which forces COMMAND
    , to run in forground.
Example:
    wl-ExecHandler.sh -c "emacs --daemon" -w "[ -f emacsExist ] && _COMMAND_ && notify-send 'Emacs daemon started.'"
```
