#!/usr/bin/env sh

# Protect against double loading and register dependencies
if printf %s\\n "${MG_MODULES:-}"|grep -q "locals"; then
  return
else
  MG_MODULES="${MG_MODULES:-} locals"
fi

# This is a cleaned up version of https://stackoverflow.com/a/18600920. It
# properly passes shellcheck's default set of rules.
if type local | grep -q "shell builtin"; then
  alias stack_let=local
  alias stack_unlet=true
else
  stack_let() {
    case "$1" in
      *=*)
        dynvar_name="${1%=*}"
        dynvar_value="${1#*=}"
        ;;
      *)
        dynvar_name=$1;
        #shellcheck disable=SC2034
        dynvar_value=${2:-""}
        ;;
    esac

    # Allow variables to be unset.
    _oldstate=$(set +o); set +u

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
