#!/bin/zsh

setopt prompt_subst
autoload colors zsh/terminfo

if [[ "$terminfo[colors]" -ge 8 ]]; then
  colors
fi

for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BLACK; do
  eval PR_$color='%{$fg[${(L)color}]%}'
  eval PR_BOLD_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
done

TERMWIDTH=${COLUMNS}

PR_NO_COLOUR="%{$terminfo[sgr0]%}"

ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=" $PR_RED*$PR_NO_COLOUR"

function _theme_line() {
  if [ $? -eq 0 ]; then
    echo "%{$PR_BOLD_BLACK%}${(l:$COLUMNS::-:)}%{$PR_NO_COLOUR%}"
  else
    echo "%{$PR_RED$?%-}${(l:$COLUMNS - $#?::-:)}%{$PR_NO_COLOUR%}"
  fi
}

function _theme_git_info() {
  if [ -z "$(git_prompt_info)" ]; then
    echo ""
  elif [ -z "$(git_prompt_short_sha)" ]; then
    echo " [$(git_prompt_info) root]"
  else
    echo " [$(git_prompt_info) $(git_prompt_short_sha)]"
  fi
}

function _theme_ssh() {
  if [ "$SSH_CLIENT" != "" ]; then
    echo "${PR_BOLD_BLUE}(SSH!)${PR_NO_COLOUR} "
  fi
}

function _theme_proxy() {
  if ! [[ -z "$HTTP_PROXY" && -z "$HTTPS_PROXY" && -z "$ALL_PROXY" ]]; then
    echo "${PR_BOLD_RED}(PROXY)${PR_NO_COLOUR} "
  fi
}

function _theme_jobs() {
  echo "%(1j.${PR_BOLD_RED}jobs:%j${PR_NO_COLOUR} .)"
}

_theme-zle-line-init() {
    [[ $CONTEXT == start ]] || return 0

    # Start regular line editor
    (( $+zle_bracketed_paste )) && print -r -n - $zle_bracketed_paste[1]
    zle .recursive-edit
    local -i ret=$?
    (( $+zle_bracketed_paste )) && print -r -n - $zle_bracketed_paste[2]

    # If we received EOT, we exit the shell
    if [[ $ret == 0 && $KEYS == $'\4' && $(jobs | wc -l) -eq 0 ]]; then
      _theme_prompt_compact=1

      zle .reset-prompt
      exit
    fi

    # Line edition is over. Shorten the current prompt.
    _theme_prompt_compact=1

    if [[ -z "${BUFFER// }" ]]; then
      _theme_prompt_compact=2
    else
      _theme_prompt_compact=1
      _theme_prompt_br=1
    fi

    zle .reset-prompt
    unset _theme_prompt_compact

    if (( ret )); then
        # Ctrl-C
        zle .send-break
    else
        # Enter
        zle .accept-line
    fi
    return ret
}
zle -N zle-line-init _theme-zle-line-init

function _theme_prompt() {
  case "${_theme_prompt_compact}" in
    1)
      echo " ${PR_MAGENTA}\$${PR_NO_COLOUR} "
      ;;
    2)
      echo ""
      ;;
    *)
      if (( $_theme_prompt_br )); then
        echo ""
      fi

      echo "%(!.${PR_RED}.${PR_BLUE})$PR_NO_COLOUR %(!.${PR_RED}root$PR_NO_COLOUR.${PR_BOLD_BLUE}%n$PR_NO_COLOUR) $(_theme_ssh)$(_theme_proxy)$(_theme_jobs)%3~$(_theme_git_info)${PR_NO_COLOUR}
%(?. .$PR_RED ! $PR_NO_COLOUR)%(!.${PR_RED}#${PR_NOCOLOR}.${PR_BLUE}>$PR_NO_COLOUR) ${PR_NO_COLOUR}"
      ;;
  esac
}

# PROMPT='$(_theme_line) ...'

PROMPT='$(_theme_prompt)'

