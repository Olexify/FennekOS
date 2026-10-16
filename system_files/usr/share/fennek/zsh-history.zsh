# Fennek OS terminal history: remembered by default (arrow up, Ctrl+R to search), shared between tabs.
#   history-off     stop saving new commands (until history-on)
#   history-on      save again
#   history-clear   delete everything saved so far
# Commands that start with a space are never saved (useful for anything secret).
_fennek_hist_off=${XDG_CONFIG_HOME:-$HOME/.config}/fennek/terminal-history-off
HISTSIZE=10000
setopt HIST_IGNORE_SPACE HIST_IGNORE_ALL_DUPS SHARE_HISTORY EXTENDED_HISTORY
if [[ -e $_fennek_hist_off ]]; then
    unset HISTFILE; SAVEHIST=0
else
    HISTFILE=$HOME/.zsh_history; SAVEHIST=10000
fi
history-off() {
    mkdir -p ${_fennek_hist_off:h} && : > $_fennek_hist_off
    unset HISTFILE; SAVEHIST=0
    print "Terminal history is off: new commands aren't saved. (history-clear deletes what's already saved.)"
}
history-on() {
    rm -f $_fennek_hist_off
    HISTFILE=$HOME/.zsh_history; SAVEHIST=10000
    print "Terminal history is on."
}
history-clear() {
    : > $HOME/.zsh_history
    local keep=$HISTSIZE; HISTSIZE=0; HISTSIZE=$keep   # also forget this session's list
    print "Saved terminal history deleted."
}
