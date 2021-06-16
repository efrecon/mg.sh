#!/usr/bin/env sh

# Protect against double loading and register dependencies
if printf %s\\n "${MG_MODULES:-}"|grep -q "interaction"; then
  return
else
  MG_MODULES="${MG_MODULES:-} interaction"
fi

if ! printf %s\\n "${MG_MODULES:-}"|grep -q "locals"; then
  printf %s\\n "This module requires the locals module" >&2
fi
if ! printf %s\\n "${MG_MODULES:-}"|grep -q "options"; then
  printf %s\\n "This module requires the options module" >&2
fi
if ! printf %s\\n "${MG_MODULES:-}"|grep -q "portability"; then
  printf %s\\n "This module requires the portability module" >&2
fi

prompt() {
  stack_let varname
  stack_let force
  stack_let hidden

  parseopts \
    --options \
      v,var,variable OPTION varname "" "Name of variable where to place result" \
      f,force FLAG force 0 "When given, this flag forces the prompt to happen even if the variable is already set" \
      h,hidden FLAG hidden 0 "Do not show what is input on screen (for secret information such as passwords)"
      help FLAG @HELP - "Print this help" \
    -- "$@"

  # shellcheck disable=SC2154 # hidden is set via the options
  if [ -n "$varname" ]; then
    # shellcheck disable=SC2154 # force is set via the options
    if var_empty "$varname" || [ "$force" = "1" ]; then
      printf %s "${2% } "
      if [ "$hidden" = "1" ]; then
        read_s -r "$1"
      else
        read -r "$1"
      fi
    fi
  else
    stack_let value
    printf %s "${2% } "
    if [ "$hidden" = "1" ]; then
      read_s -r value
    else
      read -r value
    fi
    printf %s\\n "$value"
    stack_unlet value
  fi

  stack_unlet varname force
}