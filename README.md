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
- Logs the program's output to a file in the directory specified in `TmpDir` in the script, the name would be like `swayExecHandler_CommandName.log`.
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

# Examples in Sway Conf
```
# Load gtk settings to sway
exec "wl-ExecHandler.sh -r -c 'swayLoadGTKSettings.sh' -w '_COMMAND_'"

# Start audio components, must run before waybar, otherwise waybar will crash.
exec "wl-ExecHandler.sh -R -k -c 'pipewire' -w '_COMMAND_'"
exec "wl-ExecHandler.sh -R -k -c 'wireplumber' -w '_COMMAND_'"
exec "wl-ExecHandler.sh -R -k -c 'pipewire-pulse' -w '_COMMAND_'"
exec "wl-ExecHandler.sh -R -r -c 'mpris-proxy' -w '_COMMAND_'"
exec "wl-ExecHandler.sh -R -r -c 'swayWaybarStart.sh' -w '_COMMAND_'"

# Make sure waybar starts before programs that have trays, otherwise some trays won’t show up.
# Must run after piepwire, otherwise waybar will crash.
exec "wl-ExecHandler.sh -R -r -c 'swayWaybarStart.sh' -w '_COMMAND_'"

# Start swayr(sway window switcher)
exec "wl-ExecHandler.sh -R -r -c 'swayrd' -w 'env RUST_BACKTRACE=1; RUST_LOG=swayr=debug; _COMMAND_'"

# Key simulator, used by keycursor(set in config) ..
exec "wl-ExecHandler.sh -R -k -c 'dotoold' -w '_COMMAND_'"

# Notification
exec "wl-ExecHandler.sh -R -r -c 'swaync' -w '_COMMAND_'"

# Start touchpad multi-gestures with libinput-gestures & wtype
exec "wl-ExecHandler.sh -R -k -c 'libinput-gestures -c $HOME/.config/libinput-gestures/main.conf' -w '_COMMAND_'"

# polkit gnome GUI, the binary's linked to $HOME/Bin/
exec "wl-ExecHandler.sh -R -k -c 'polkit-gnome-authentication-agent-1' -w '_COMMAND_'"

# Start fcitx input method framework
exec "sleep 4 && wl-ExecHandler.sh -R -r -c 'fcitx5 -d' -w '_COMMAND_'"

# Bluetooth manager system tray
exec "sleep 4 && wl-ExecHandler.sh -R -r -c 'blueman-applet' -w '_COMMAND_'"

# Start cmst(connman qt gui configuration tool)
# Make sure waybar is launched before cmst, othewrise cmst tray won’t show up
exec "sleep 4 && wl-ExecHandler.sh -R -r -c 'cmst -m' -w '_COMMAND_'"

```

