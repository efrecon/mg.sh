#!/bin/sh

# Set this to force home-made implementation in favour of local builtin
__MG_LOCALS_FORCE=${__MG_LOCALS_FORCE:-0}

# This is a cleaned up version of https://stackoverflow.com/a/18600920. It
# properly passes shellcheck's default set of rules.
if [ "$__MG_LOCALS_FORCE" = "0" ] && type local 2>/dev/null | grep -q "shell builtin"; then
  if [ -n "${BASH:-}" ]; then
    # Remove any exiting aliases
    alias | sed -E 's/^alias\s+([^=]+)=.*/\1/g' | while IFS= read -r __alias; do
      unalias "$__alias"
    done
    # shellcheck disable=SC3044 # We are running in bash!!
    shopt -s expand_aliases
  fi
  alias stack_let=local
  alias stack_unlet=true
else
  stack_let() {
    # Allow variables to be unset.
    _oldstate=$(set +o); set +u

    while [ "$#" -gt "0" ]; do
      if printf %s\\n "$1" | grep -q "="; then
        dynvar_name="${1%=*}"
        # shellcheck disable=SC2034  # It IS used below!
        dynvar_value="${1#*=}"
      else
        dynvar_name="$1"
        # shellcheck disable=SC2034  # It IS used below!
        dynvar_value=
      fi

      dynvar_count_var=${dynvar_name}_dynvar_count
      if [ "$(eval echo "$dynvar_count_var")" ]; then
        eval "$dynvar_count_var"='$(( $'"$dynvar_count_var"' + 1 ))'
      else
        eval "$dynvar_count_var"=0
      fi

      eval dynvar_oldval_var="${dynvar_name}"_oldval_'$'"$dynvar_count_var"
      #shellcheck disable=SC2154
      eval "$dynvar_oldval_var"='$'"$dynvar_name"

      eval "$dynvar_name"='$'dynvar_value

      shift
    done

    # Restore set state
    set +vx; eval "$_oldstate"
  }

  stack_unlet() {
    for dynvar_name; do
      dynvar_count_var=${dynvar_name}_dynvar_count
      eval dynvar_oldval_var="${dynvar_name}"_oldval_'$'"$dynvar_count_var"
      eval "$dynvar_name"='$'"$dynvar_oldval_var"
      eval unset "$dynvar_oldval_var"
      eval "$dynvar_count_var"='$(( $'"$dynvar_count_var"' - 1 ))'
    done
  }
fi

# Declare two aliases so we can call let/unlet (and accept shellcheck warnings)
let() { stack_let "$@"; }
unlet() { stack_unlet "$@"; }
