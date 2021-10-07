#!/bin/sh

module locals options controls portability

prompt() {
  stack_let destination=
  stack_let force
  stack_let hidden
  stack_let begin
  stack_let question=

  parseopts \
    --options \
      v,var,variable,varname OPTION destination - "Name of variable where to place result" \
      f,force FLAG force 0 "When given, this flag forces the prompt to happen even if the variable is already set" \
      h,hidden FLAG hidden 0 "Do not show what is input on screen (for secret information such as passwords)" \
      help FLAG @HELP - "Print this help" \
    --shift _begin \
    -- "$@"

  # shellcheck disable=SC2154  # Var is set by parseopts
  shift "$_begin"

  [ "$#" -gt 0 ] && question="${1% } "
  # shellcheck disable=SC2154 # hidden is set via the options
  if [ -n "$destination" ]; then
    # shellcheck disable=SC2154 # force is set via the options
    if var_empty "$destination" || [ "$force" = "1" ]; then
      printf %s "${question}"
      if [ "$hidden" = "1" ]; then
        read_s -r "$destination"
      else
        # shellcheck disable=SC2229  # Yes! We actually want the result in the var which name was passed as an option
        read -r "$destination"
      fi
    fi
  else
    stack_let value
    printf %s "${question}"
    if [ "$hidden" = "1" ]; then
      read_s -r value
    else
      read -r value
    fi
    printf %s\\n "$value"
    stack_unlet value
  fi

  stack_unlet destination force begin question
}