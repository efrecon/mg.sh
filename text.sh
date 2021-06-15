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
      c,charset OPTION _charset "A-Za-z0-9" "Set of allowed characters (tr compatible)" \
      h,help FLAG @HELP - "Print this help" \
    -- "$@"

  # shellcheck disable=SC2154 # Declared locally with stack_let
  LC_ALL=C tr -dc "${_charset}" </dev/urandom 2>/dev/null | head -c"$((_len*3))" | tr -d '\n' | tr -d '\0' | head -c"$_len"
  stack_unlet _len _charset
}
