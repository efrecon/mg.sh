#!/usr/bin/env sh

set -eu

abspath() {
  if [ -d "$1" ]; then
    ( cd -P -- "$1" && pwd -P )
  elif [ -L "$1" ]; then
    abspath "$(dirname "$1")/$(readlink "$1")"
  else
    printf %s\\n "$(abspath "$(dirname "$1")")/$(basename "$1")"
  fi
}

MG_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$(abspath "$0")")")" && pwd -P )
MG_LIBPATH=${MG_LIBPATH:-${MG_ROOTDIR}/..}

# Look for modules passed as parameters in the DEW_LIBPATH and source them.
# Modules are required so fail as soon as it was not possible to load a module
module() {
  for module in "$@"; do
    for d in $(printf %s\\n "$MG_LIBPATH" | awk '{split($1,DIRS,/:/); for ( D in DIRS ) {printf "%s\n", DIRS[D];} }'); do
      if [ -f "${d}/${module}.sh" ]; then
        # shellcheck disable=SC1090
        . "${d}/${module}.sh"
        unset module; # Use the variable as a marker for module found.
        break
      fi
    done
    if [ -n "${module:-}" ]; then
      echo "Cannot find module $module in $MG_LIBPATH !" >& 2
      exit 1
    fi
  done
}

module locals log options controls filesystem portability text interaction

if type "$MG_APPNAME" 1>&2 >/dev/null; then
  "$MG_APPNAME" "$@"
else
  dir "$MG_APPNAME is not a function of the mg.sh API"
fi