#!/bin/sh

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
# shellcheck disable=SC1091
. "${MG_ROOTDIR}/../bootstrap.sh"

PACK_OVERRIDE=${PACK_OVERRIDE:-0}
PACK_OUTPUT=${PACK_OUTPUT:-"-"}

usage() {
  # This uses the comments behind the options to show the help. Not extremly
  # correct, but effective and simple.
  echo "$0 Pack a set of modules into a single file, ready to be sourced. Usage:" && \
    grep "[[:space:]].)\ #" "$0" |
    sed 's/#//' |
    sed -r 's/([a-z])\)/-\1/'
  exit "${1:-0}"
}

# We cannot use our own options parsing module to be able to perfectly select
# the set of modules to pack.
while getopts "o:wh-" opt; do
  case "$opt" in
    o) # File to output to, - or empty for stdout (the default).
      PACK_OUTPUT=$OPTARG;;
    w) # Overwrite file if it exists (default is to bail out).
      PACK_OVERRIDE=1;;
    h) # Print this help and exit
      usage;;
    -)
      break;;
    *)
      usage 1;;
  esac
done
shift $((OPTIND-1))

if [ "$#" -gt "0" ]; then
  module "$@"
else
  # shellcheck disable=SC2046 # On purpose, we want the list.
  module $(find "${MG_ROOTDIR}/.." -maxdepth 1 -name '*.sh' -exec basename \{\} \; | sed -E 's/.sh$//' | sort)
fi

dump() {
  _src=$(path_search "$MG_LIBPATH" "${1}.sh")
  printf "#### mg.sh\n"
  printf "# Module:\t%s\n" "$1"
  printf "# Date  :\t%s\n" "$(date +'%Y%m%d-%H%M%S')"
  printf "# Origin:\t%s\n" "$_src"
  cat "$_src"
  printf "\n"
}

modules() {
  printf "#### mg.sh\n"
  printf "# Picked:\t%s\n" "$MG_MODULES"
  printf "# Date  :\t%s\n" "$(date +'%Y%m%d-%H%M%S')"
  printf "MG_MODULES=\"%s\"\n" "$MG_MODULES"
  # shellcheck disable=SC2016 # This is ok, we want to output the setting line!
  printf 'MG_LIBPATH=${MG_LIBPATH:-"-"}\n\n'
}

# Remove existing file or bail out early
if [ -n "$PACK_OUTPUT" ] && [ "$PACK_OUTPUT" != "-" ] && [ -f "$PACK_OUTPUT" ]; then
  if [ "$PACK_OVERRIDE" = "0" ]; then
    echo "File at $PACK_OUTPUT already exists!" >& 2
    exit 2
  else
    rm -f "$PACK_OUTPUT"
  fi
fi

for module in $MG_MODULES; do
  # Print out the content of the module, with some header information
  if [ "$PACK_OUTPUT" = "-" ] || [ -z "$PACK_OUTPUT" ]; then
    dump "$module"
  else
    dump "$module" >> "$PACK_OUTPUT"
  fi

  # Once the bootstrap module has been dumped, print out the list of modules
  # that were selected through the command-line and dependencies, so as to
  # prevent actively looking for modules when modules which content will be
  # dumped further down the loop express their dependencies through calling the
  # module function.
  if [ "$module" = "bootstrap" ]; then
    if [ "$PACK_OUTPUT" = "-" ] || [ -z "$PACK_OUTPUT" ]; then
      modules
    else
      modules >> "$PACK_OUTPUT"
    fi
  fi
done
