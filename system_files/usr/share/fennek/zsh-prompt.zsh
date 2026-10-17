# Fennek OS terminal prompt: your name (violet), the folder you're in (grey), then ❯ (red after a failed command).
#   anna ~/Documents ❯
# Your own PROMPT in ~/.zshrc wins (it is read after this).
PROMPT='%F{141}%n%f %F{247}%~%f %(?.%F{255}.%F{203})❯%f '
