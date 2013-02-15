# Source local zsh config first
for config (~/.zsh/*.zsh) source $config

###############################################################################
# Oh My Zsh
################################################################################
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="agnoster"
DISABLE_AUTO_TITLE="true"
COMPLETION_WAITING_DOTS="true"
DEFAULT_USER=$USER
plugins=(git brew osx vi-mode)
source $ZSH/oh-my-zsh.sh

################################################################################
# General
################################################################################
# Uncomment if we want tmux powerline to display the current directory
# PS1="$PS1"'$([ -n "$TMUX" ] && tmux setenv TMUXPWD_$(tmux display -p "#D" | tr -d %) "$PWD")'

# Disable sound
setopt no_beep

# Disable auto correct
unsetopt correct_all

# Export TERM correctly for tmux
[[ $TERM == "screen" ]] && export TERM=screen-256color
[[ $TERM == "xterm" ]] && export TERM=xterm-256color

# Enable dircolors if we're in Linux
if [[ "$(uname)" == "Linux" ]]; then
  eval `dircolors ~/.dircolors`
fi

# Turn off terminal driver flow control (CTRL+S/CTRL+Q)
setopt noflowcontrol
stty -ixon -ixoff

autoload zmv

################################################################################
# Vars
################################################################################
export PATH=~/.dotfiles/bin:~/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/share/python
export EDITOR=vim
# Use vimpager as PAGER
export VIMPAGER_RC=~/.dotfiles/.zsh/.vimpagerrc
export PAGER=~/.dotfiles/.zsh/vimpager/vimpager
export VISUAL=vim
export P4DIFF="gvimdiff -f -R"
if [ -f /usr/local/heroku/bin/heroku ]; then
  export PATH=/usr/local/heroku/bin:$PATH
fi
export KEYTIMEOUT=1

################################################################################
# Aliases
################################################################################
# p4merge
if [[ "$(uname)" == "Darwin" ]]; then
  alias p4merge='/Applications/p4merge.app/Contents/MacOS/p4merge'
fi

# Open file in existing  gvim
alias gvir='gvim --remote'

# Enable reattach-to-user-namespace on Mac. See
# https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard/issues/8
if [[ "$(uname)" == "Darwin" ]]; then
  alias tmux='tmux -2 -f ~/.dotfiles/.tmux-osx.conf'
else
  alias tmux='tmux -2'
fi

alias less=$PAGER
alias zless=$PAGER

alias ←="pushd -q +1"
alias →="pushd -q -0"

################################################################################
# Ruby
################################################################################
# Initialize rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

################################################################################
# fasd
################################################################################
alias v='f -e vim'
fasd_cache="$HOME/.fasd-init-bash"
if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
  fasd --init posix-alias zsh-{hook,ccomp,ccomp-install,wcomp,wcomp-install} >| "$fasd_cache"
fi
source "$fasd_cache"
unset fasd_cache

################################################################################
# Teamocil
################################################################################
alias t="teamocil --here"
compctl -g '~/.teamocil/*(:t:r)' teamocil

################################################################################
# ZLE Widgets
################################################################################
# Zsh's history-beginning-search-backward is very close to Vim's C-x C-l
history-beginning-search-backward-then-append() {
  zle history-beginning-search-backward
  zle vi-add-eol
}
zle -N history-beginning-search-backward-then-append

# Delete all characters between a pair of characters. Mimics vim's "di" text object functionality
delete-in() {

  # Create locally-scoped variables we'll need
  local CHAR LCHAR RCHAR LSEARCH RSEARCH COUNT

  # Read the character to indicate which text object we're deleting
  read -k CHAR

  if [ "$CHAR" = "w" ]
  then
    # diw, delete the word

    # find the beginning of the word under the cursor
    zle vi-backward-word

    # set the left side of the delete region at this point
    LSEARCH=$CURSOR

    # find the end of the word under the cursor
    zle vi-forward-word

    # set the right side of the delete region at this point
    RSEARCH=$CURSOR

    # Set the BUFFER to everything except the word we are removing
    RBUFFER="$BUFFER[$RSEARCH+1,${#BUFFER}]"
    LBUFFER="$LBUFFER[1,$LSEARCH]"

    return

  # diw was unique.  For everything else, we just have to define the
  # characters to the left and right of the cursor to be removed
  elif [ "$CHAR" = "(" ] || [ "$CHAR" = ")" ]
  then
    # di), delete inside of a pair of parenthesis
    LCHAR="("
    RCHAR=")"

  elif [ "$CHAR" = "[" ] || [ "$CHAR" = "]" ]
  then
    # di], delete inside of a pair of square brackets
    LCHAR="["
    RCHAR="]"

  elif [ $CHAR = "{" ] || [ $CHAR = "}" ]
  then
    # di}, delete inside of a pair of braces
    LCHAR="{"
    RCHAR="}"

  else
    # The character entered does not have a special definition.
    # Simply find the first instance to the left and right of the cursor.
    LCHAR="$CHAR"
    RCHAR="$CHAR"
  fi

  # Find the first instance of LCHAR to the left of the cursor and the
  # first instance of RCHAR to the right of the cursor, and remove everything in between.
  # Begin the search for the left-sided character directly the left of the cursor
  LSEARCH=${#LBUFFER}

  # Keep going left until we find the character or hit the beginning of the buffer
  while [ "$LSEARCH" -gt 0 ] && [ "$LBUFFER[$LSEARCH]" != "$LCHAR" ]
  do
    LSEARCH=$(expr $LSEARCH - 1)
  done

  # If we hit the beginning of the command line without finding the character, abort
  if [ "$LBUFFER[$LSEARCH]" != "$LCHAR" ]
  then
    return
  fi

  # start the search directly to the right of the cursor
  RSEARCH=0

  # Keep going right until we find the character or hit the end of the buffer
  while [ "$RSEARCH" -lt $(expr ${#RBUFFER} + 1 ) ] && [ "$RBUFFER[$RSEARCH]" != "$RCHAR" ]
  do
    RSEARCH=$(expr $RSEARCH + 1)
  done

  # If we hit the end of the command line without finding the character, abort
  if [ "$RBUFFER[$RSEARCH]" != "$RCHAR" ]
  then
    return
  fi

  # Set the BUFFER to everything except the text we are removing
  RBUFFER="$RBUFFER[$RSEARCH,${#RBUFFER}]"
  LBUFFER="$LBUFFER[1,$LSEARCH]"
}

zle -N delete-in

# Delete all characters between a pair of characters and then go to insert mode
# Mimics vim's "ci" text object functionality.
change-in() {
  zle delete-in
  zle vi-insert
}
zle -N change-in

# Delete all characters between a pair of characters as well as the surrounding
# characters themselves. Mimics vim's "da" text object functionality
delete-around() {
  zle delete-in
  zle vi-backward-char
  zle vi-delete-char
  zle vi-delete-char
}
zle -N delete-around

# Delete all characters between a pair of characters as well as the surrounding
# characters themselves and then go into insert mode. Mimics vim's "ca" text
# object functionality.
change-around() {
  zle delete-in
  zle vi-backward-char
  zle vi-delete-char
  zle vi-delete-char
  zle vi-insert
}
zle -N change-around

################################################################################
# Key bindings
################################################################################
case "$TERM" in
  *xterm*|screen-256color)
    # alt + arrows (Alt-arrow is used to switch panes in tmux)
    # bindkey '[d' backward-word
    # bindkey '[c' forward-word
    # bindkey '^[[1;3d' backward-word
    # bindkey '^[[1;3c' forward-word

    # ctrl + arrows
    bindkey '^[od' backward-word
    bindkey '^[oc' forward-word
    bindkey '^[[1;5D' backward-word
    bindkey '^[[1;5C' forward-word

    # home / end
    bindkey '^[[1~' beginning-of-line
    bindkey '^[[4~' end-of-line

    # delete
    bindkey '^[[3~' delete-char

    # page up / page down
    bindkey '^[[5~' history-beginning-search-backward
    bindkey '^[[6~' history-beginning-search-forward

    # shift + tab
    bindkey '^[[Z' reverse-menu-complete

    # VI MODE KEYBINDINGS (ins mode)

    # Marking, yanking, and pasting in insert mode
    # Ctrl-t to set the mark, use movement commands to select the region, yank
    # the region using Ctrl-y, and paste the region using Ctrl-p

    # Backspace: Delete previous char
    bindkey -M viins '^?' backward-delete-char
    # Ctrl-q: Delete next word
    bindkey -M viins '^q' kill-word
    # Ctrl-w: Delete previous word
    bindkey -M viins '^w' backward-kill-word
    # Ctrl-e: Move to the end of line
    bindkey -M viins '^e' end-of-line
    # Ctrl-r: Search backwards in history
    bindkey -M viins '^r' history-incremental-pattern-search-backward
    # Ctrl-t: Set mark
    bindkey -M viins '^t' set-mark-command
    # Ctrl-y: Copy the area from the cursor to the mark to the kill buffer
    bindkey -M viins '^y' copy-region-as-kill
    # Ctrl-u: Deletes everything before cursor (u is on left)
    bindkey -M viins '^u' backward-kill-line
    # Ctrl-o: Deletes everything after cursor (o is on right) (Commonly Ctrl-k)
    bindkey -M viins '^o' kill-line
    # Ctrl-p: Insert the contents of the kill buffer at the cursor
    bindkey -M viins '^p' yank
    # Ctrl-a: Go to the beginning of line
    bindkey -M viins '^a' beginning-of-line
    # Ctrl-s: Search forwards in history
    bindkey -M viins '^s' history-incremental-pattern-search-forward
    # Ctrl-d: Exit
    # Ctrl-f: Move to next directory in history
    bindkey -M viins -s '^f' "→\r"
    # Ctrl-g: Undo
    bindkey -M viins '^g' undo
    # Ctrl-h: Move one character to the left
    bindkey -M viins '^h' backward-char
    # Ctrl-j: Go down in history
    bindkey -M viins '^j' down-line-or-history
    # Ctrl-k: Go up in history
    bindkey -M viins '^k' up-line-or-history
    # Ctrl-l: Move one character to the right
    bindkey -M viins '^l' forward-char
    # Ctrl-z: Tmux command key
    # Ctrl-x: Delete character under cursor
    bindkey -M viins '^x' delete-char
    # Ctrl-c: Terminates
    # Ctrl-b: Move to previous directory in history
    bindkey -M viins -s '^b' "←\r" # C-b move to previous directory (in history)
    # Ctrl-m: Same as Enter
    # Ctrl-n: Clear the entire screen (cleaN)
    bindkey -M viins '^n' clear-screen

    # Alt-j: Move one word to the left
    bindkey -M viins '^[j' backward-word
    # Alt-k: Move one word to the right
    bindkey -M viins '^[k' forward-word

    bindkey -M viins '^_'    undo

    # Up/Down arrow keys: Go up or down in history
    bindkey -M viins '\eOA'  up-line-or-history
    bindkey -M viins '^[[A'  up-line-or-history
    bindkey -M viins '\eOB'  down-line-or-history
    bindkey -M viins '^[[B'  down-line-or-history

    # VI MODE KEYBINDINGS (cmd mode)
    bindkey -M vicmd 'ca'    change-around
    bindkey -M vicmd 'ci'    change-in
    bindkey -M vicmd 'da'    delete-around
    bindkey -M vicmd 'di'    delete-in
    bindkey -M vicmd 'ga'    what-cursor-position
    bindkey -M vicmd 'gg'    beginning-of-history
    bindkey -M vicmd 'G '    end-of-history
    bindkey -M vicmd '^a'    beginning-of-line
    bindkey -M vicmd '^e'    end-of-line
    bindkey -M vicmd '^k'    kill-line
    bindkey -M vicmd '^r'    history-incremental-pattern-search-backward
    bindkey -M vicmd '^s'    history-incremental-pattern-search-forward
    bindkey -M vicmd '^p'    history-beginning-search-backward
    bindkey -M vicmd '^n'    history-beginning-search-forward
    bindkey -M vicmd '^y'    yank
    bindkey -M vicmd '^w'    backward-kill-word
    bindkey -M vicmd '^u'    backward-kill-line
    bindkey -M vicmd '/'     vi-history-search-forward
    bindkey -M vicmd '?'     vi-history-search-backward
    bindkey -M vicmd '^_'    undo
    bindkey -M vicmd '\ef'   forward-word                      # Alt-f
    bindkey -M vicmd '\eb'   backward-word                     # Alt-b
    bindkey -M vicmd '\ed'   kill-word                         # Alt-d
    bindkey -M vicmd '\e[5~' history-beginning-search-backward # PageUp
    bindkey -M vicmd '\e[6~' history-beginning-search-forward  # PageDown
  ;;
esac

################################################################################
# Vim mode
################################################################################
# vim mode indicator in prompt
# (http://superuser.com/questions/151803/how-do-i-customize-zshs-vim-mode)
vim_ins_mode="%{$fg[cyan]%}[INS]%{$reset_color%}"
vim_cmd_mode="%{$fg[green]%}[CMD]%{$reset_color%}"
vim_mode=$vim_ins_mode

function zle-keymap-select {
  vim_mode="${${KEYMAP/vicmd/${vim_cmd_mode}}/(main|viins)/${vim_ins_mode}}"
  zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-finish {
  vim_mode=$vim_ins_mode
}
zle -N zle-line-finish

RPROMPT='${vim_mode}'

################################################################################
# END
################################################################################
