#!/usr/bin/env sh

# Protect against double loading and register dependencies
if printf %s\\n "${MG_MODULES:-}"|grep -q "text"; then
  return
else
  MG_MODULES="${MG_MODULES:-} text"
fi

if ! printf %s\\n "${MG_MODULES:-}"|grep -q "locals"; then
  printf %s\\n "This module requires the locals module" >&2
fi
if ! printf %s\\n "${MG_MODULES:-}"|grep -q "options"; then
  printf %s\\n "This module requires the options module" >&2
fi

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
      *)
        return 1; break;;
    esac
    shift
  done
}

is_true() { test "$(unboolean "$1")" = "1"; }
is_false() { test "$(unboolean "$1")" = "0"; }
