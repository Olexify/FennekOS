# Fennek OS: a pending "Reset desktop settings" (Settings > Update & Recovery) happens here, before the desktop
# starts, so the desktop comes up with Fennek's defaults (see /usr/libexec/fennek-reset-settings).
[ -e "${XDG_STATE_HOME:-$HOME/.local/state}/fennek-reset-pending" ] && /usr/libexec/fennek-reset-settings --now
