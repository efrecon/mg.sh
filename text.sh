#!/bin/sh

module locals options

# Generate a random string.
rndstr() {
  stack_let _len
  stack_let _charset

  parseopts \
    --options \
      l,len,length OPTION _len 8 "Length of random string" \
      c,charset OPTION _charset "A-Za-z0-9,._+:@%-" "Set of allowed characters (tr compatible)" \
      h,help FLAG @HELP - "Print this help" \
    -- "$@"

  # shellcheck disable=SC2154 # Declared locally with stack_let
  LC_ALL=C tr -dc "${_charset}" </dev/urandom 2>/dev/null | head -c"$((_len*3))" | tr -d '\n' | tr -d '\0' | head -c"$_len"
  stack_unlet _len _charset
}

tr_echo() {
  if [ "$#" -lt "2" ]; then
    return 1;
  elif [ "$#" = "2" ]; then
    tr "$1" "$2"
  elif [ "$#" = "3" ]; then
    printf %s\\n "$3" | tr_echo "$1" "$2"
  else
    stack_let _fromClass="$1"
    stack_let _toClass="$2"
    shift 2

    # shellcheck disable=SC2154 # from and to class declared local
    {
      while [ "$#" -gt "0" ]; do
        printf "%s " "$1"; shift
      done
      printf \\n
    } | sed 's/ $//' | tr_echo "$_fromClass" "$_toClass"

    stack_unlet _fromClass _toClass
  fi
}

to_lower() { tr_echo '[:upper:]' '[:lower:]' "$@"; }
to_upper() { tr_echo '[:lower:]' '[:upper:]' "$@"; }

unboolean() {
  while [ "$#" -gt "0" ]; do
    case "$(to_lower "$1")" in
      on|true|t|yes|y)
        printf 1\\n;;
      off|false|f|no|n)
        printf 0\\n;;
      [0-9] | [0-9][0-9] | [0-9][0-9][0-9] | [0-9][0-9][0-9][0-9] | [0-9][0-9][0-9][0-9][0-9] | [0-9][0-9][0-9][0-9][0-9][0-9] | [0-9][0-9][0-9][0-9][0-9][0-9][0-9] | [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
        if [ "$1" = "0" ]; then
          printf 0\\n
        else
          printf 1\\n
        fi;;
      *)
        return 1; break;;
    esac
    shift
  done
}

is_true() { test "$(unboolean "$1")" = "1"; }
is_false() { test "$(unboolean "$1")" = "0"; }

# Join passed arguments with a separator, which can be of any length. Strongly
# inspired by https://serverfault.com/a/936545
strjoin() {
  if [ "$#" -lt "2" ]; then return; fi
  stack_let joiner
  joiner="$1"
  shift
  while [ "$#" -gt "1" ]; do
    printf %s%s "$1" "$joiner"
    shift
  done
  printf %s\\n "$1"
  stack_unlet joiner
}

# Split $2 on separator at $1. Separator can only be one char long.
strsplit() {
  [ -z "${1:-}" ] && echo "${2:-}" && return
  stack_let _oldstate
  # Disable globbing.
  # This ensures that the word-splitting is safe.
  _oldstate=$(set +o); set -f

  # Store the current value of 'IFS' so we
  # can restore it later.
  old_ifs=$IFS

  # Change the field separator to what we're
  # splitting on.
  IFS=$1

  # Create an argument list splitting at each
  # occurance of '$2'.
  #
  # This is safe to disable as it just warns against
  # word-splitting which is the behavior we expect.
  # shellcheck disable=2086
  set -- $2

  # Print each list value on its own line.
  printf '%s\n' "$@"

  # Restore the value of 'IFS'.
  IFS=$old_ifs

  # Restore globbing state
  set +vx; eval "$_oldstate"
  stack_unlet _oldstate
}