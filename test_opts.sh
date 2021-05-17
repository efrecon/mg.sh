#!/usr/bin/env sh

# Build a default colon separated TOPT_LIBPATH using the root directory to
# look for modules that this script depends on. TOPT_LIBPATH can be set
# from the outside to facilitate location. Note that this only works when there
# is support for readlink -f, see https://github.com/ko1nksm/readlinkf for a
# POSIX alternative.
TOPT_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$(readlink -f "$0")")")" && pwd -P )
TOPT_LIBPATH=${TOPT_LIBPATH:-/usr/local/share/mg.sh:${TOPT_ROOTDIR}/lib/mg.sh:${TOPT_ROOTDIR}}

# Look for modules passed as parameters in the TOPT_LIBPATH and source them.
# Modules are required so fail as soon as it was not possible to load a module
module() {
  for module in "$@"; do
    OIFS=$IFS
    IFS=:
    for d in $TOPT_LIBPATH; do
      if [ -f "${d}/${module}.sh" ]; then
        # shellcheck disable=SC1090
        . "${d}/${module}.sh"
        IFS=$OIFS
        break
      fi
    done
    if [ "$IFS" = ":" ]; then
      echo "Cannot find module $module in $TOPT_LIBPATH !" >& 2
      exit 1
    fi
  done
}

# Source in all relevant modules.
module log locals options

callback() {
  echo "$1 => $2"
}
MG_VERBOSITY=trace
parseopts \
  --prefix TOPT \
  --options \
      h,help FLAG @HELP - "Gives this very long help to test if we properly wrap text when outputing stuff and exit" \
      s,sleep,wait OPTION WAIT 10 "How long to wait" \
      trigger OPTION @callback 46 "Generate a callback" \
  --main \
  -- "$@"
set | grep "^TOPT"