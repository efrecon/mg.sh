#!/bin/sh

# Set this to force home-made implementation in favour of local builtin
__MG_PORTABILITY_FORCE=${__MG_PORTABILITY_FORCE:-0}

module locals filesystem

b64_encode() { base64; }
b64_decode() {
  if [ "$(uname -s)" = "Darwin" ]; then
    base64 -D; # Mac takes -D or --decode
  else
    base64 -d; # Alpine/budybox does not understand --decode
  fi
}

# This is the same as read -s, which is not portable. All other options to read
# are carried out.
read_s() {
  stack_let oldtty

  if [ -t 0 ]; then
    # Disable echo.
    oldtty=$(stty -g)
    stty -echo

    # Set up trap to ensure echo is enabled before exiting if the script
    # is terminated while echo is disabled.
    trap 'stty echo' EXIT
  fi

  # Read secret.
  # shellcheck disable=SC2162 # We want this read function to have same options!
  read "$@"

  if [ -t 0 ]; then
    # Enable echo.
    stty echo
    trap - EXIT
    stty "$oldtty"

    # Print a newline because the newline entered by the user after
    # entering the passcode is not echoed. This ensures that the
    # next line of output begins at a new line.
    printf \\n
  fi

  stack_unlet oldtty
}

# This is the same as readlink -f, which does not exist on MacOS
readlink_f() {
  if [ -d "$1" ]; then
    ( cd -P -- "$1" && pwd -P )
  elif [ -L "$1" ]; then
    if is_abspath "$(readlink "$1")"; then
      readlink_f "$(readlink "$1")"
    else
      readlink_f "$(dirname "$1")/$(readlink "$1")"
    fi
  else
    printf %s\\n "$(readlink_f "$(dirname "$1")")/$(basename "$1")"
  fi
}


# This is an expansion safe envsubst implementation in pure-shell and inspired
# by https://stackoverflow.com/a/40167919. It uses eval in a controlled-manner
# to avoid side-effects. It also supports SHELL-FORMAT, i.e. recognises inside
# the first argument, the (restricted) list of environment variables that should
# be replaced (i.e. all variables written as $FOO or ${FOO} inside the value of
# the first argument)
# shellcheck disable=SC2120
mg_envsubst() (
  varlist='[A-Z_][A-Z0-9_]*'
  if [ "$#" -ge "1" ]; then
    # shellcheck disable=SC2016
    varlist=$(  printf %s\\n "$1" |
                  grep -Eo -e '\$[A-Z_][A-Z0-9_]*' -e '\${[A-Z_][A-Z0-9_]*}' |
                  sed -E -e 's/^\$//g' -e 's/^\{([A-Z_][A-Z0-9_]*)\}/\1/g'|
                  awk -v d="|" '{s=(NR==1?s:s d)$0}END{print s}')
  fi

  while IFS= read -r line || [ -n "$line" ]; do  # Read, incl. non-empty last line
    # Transform everything that looks like an environment variable (all
    # caps, no first digit) to its {} equivalent. This transform
    # understands \$ quoting, but will fail within single quotes. Then
    # escape ALL characters that could trigger an expansion.
    IFS= read -r _lineEscaped << EOF
$(printf %s "$line" | sed -E -e "s/([^\\\\])\\\$(${varlist})/\\1\\\${\\2}/g" -e "s/^\\\$(${varlist})/\\\${\\1}/g" | tr '`([$' '\1\2\3\4')
EOF
    # ... then selectively reenable ${ references
    _lineEscaped=$(printf %s\\n "$_lineEscaped" | sed -e 's/\x04{/${/g' -e 's/"/\\\"/g')
    # Disable unset errors to ensure we output something (with empty
    # value for var)
    _oldstate=$(set +o); set +u
    # At this point, eval is safe, since the only expansion left is for
    # ${} contructs. Perform the eval, variables that do not exist will
    # be replaced by an empty string.
    _lineResolved=$(eval "printf '%s\n' \"$_lineEscaped\"")
    # Restore set state
    set +vx; eval "$_oldstate"
    # and convert back the control characters to the real chars.
    printf %s\\n "$_lineResolved" | tr '\1\2\3\4' '`([$'
  done
)

# Install mg_envsubst automatically as envsubst when it does not exist.
if [ "$__MG_PORTABILITY_FORCE" = "1" ] || ! command -v envsubst >/dev/null; then
  alias envsubst=mg_envsubst
fi