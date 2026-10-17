# Classic commands that have another name here: say which, and run it only after "y".
#   md Photos  ->  In Fennek OS this is: mkdir -p Photos   Run it? [y/N]
typeset -gA _fennek_familiar=(
    md 'mkdir -p'  rd rmdir  ren mv  xcopy 'cp -r'  findstr grep  tracert tracepath
    notepad kwrite  explorer dolphin  ver 'cat /etc/os-release'  systeminfo hostnamectl  chkdsk 'df -h'
)
command_not_found_handler() {
    local cmd=${_fennek_familiar[$1]}
    if [[ -z $cmd ]]; then print -u2 "zsh: command not found: $1"; return 127; fi
    shift
    local -a args; args=(${(q)@})   # each argument quoted, so "a b" stays one name
    local full=$cmd
    (( $# )) && full+=" ${(j: :)args}"
    print -u2 "In Fennek OS this is: $full"
    read -q -u 0 "?Run it? [y/N] " || { print -u2; return 127; }
    print -u2
    eval "$full"
}
