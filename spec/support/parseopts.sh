#!/usr/bin/env sh

set -eu

# Find out where dependent modules are and load them at once before doing
# anything. This is to be able to use their services as soon as possible.

# Build a default colon separated DEW_LIBPATH using the root directory to look
# for modules that we depend on. DEW_LIBPATH can be set from the outside to
# facilitate location. Note that this only works when there is support for
# readlink -f, see https://github.com/ko1nksm/readlinkf for a POSIX alternative.
PARSEOPTS_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$(readlink -f "$0")")")" && pwd -P )
PARSEOPTS_LIBPATH=${PARSEOPTS_LIBPATH:-${PARSEOPTS_ROOTDIR}/../..}

# Look for modules passed as parameters in the DEW_LIBPATH and source them.
# Modules are required so fail as soon as it was not possible to load a module
module() {
  for module in "$@"; do
    OIFS=$IFS
    IFS=:
    for d in $PARSEOPTS_LIBPATH; do
      if [ -f "${d}/${module}.sh" ]; then
        # shellcheck disable=SC1090
        . "${d}/${module}.sh"
        IFS=$OIFS
        break
      fi
    done
    if [ "$IFS" = ":" ]; then
      echo "Cannot find module $module in $PARSEOPTS_LIBPATH !" >& 2
      exit 1
    fi
  done
}

# Source in all relevant modules. This is where most of the "stuff" will occur.
module log locals options

trigger() {
  printf %s=%s\\n "$1" "$2"
}

parseopts "$@"