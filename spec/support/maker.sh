#!/bin/sh

# This will create a mg.sh caller, similar to the one in the bin directory, but
# using the services of the pack.sh script. This is used in tests (pack_spec.sh)
# to make sure that we are able to pack stuff into a single library, and use
# that library to callout functions of the library.

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

MAKER_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$(abspath "$0")")")" && pwd -P )
MG_ROOTDIR=$(abspath "${MAKER_ROOTDIR}/../..")

# Directory where to find snippets
MAKER_SNIPPETS=${MAKER_SNIPPETS:-"${MAKER_ROOTDIR%/}/maker.d"}

# Set to 1 to allow override of output file
MAKER_OVERRIDE=${MAKER_OVERRIDE:-0}

usage() {
  # This uses the comments behind the options to show the help. Not extremly
  # correct, but effective and simple.
  echo "$0 creates a mg.sh wrapper. Usage:" && \
    grep "[[:space:]].)\ #" "$0" |
    sed 's/#//' |
    sed -r 's/([a-z])\)/-\1/'
  exit "${1:-0}"
}

# We cannot use our own options parsing module to be able to perfectly select
# the set of modules to pack.
while getopts "s:wh-" opt; do
  case "$opt" in
    s) # Path to directory with snippets to concatenate for wrapping
      MAKER_SNIPPETS=$OPTARG;;
    w) # Overwrite file if it exists (default is to bail out).
      MAKER_OVERRIDE=1;;
    h) # Print this help and exit
      usage;;
    -)
      break;;
    *)
      usage 1;;
  esac
done
shift $((OPTIND-1))


dump() {
  find -L "$MAKER_SNIPPETS" -maxdepth 1 -mindepth 1 -name '*.sh' -type f |
    sort | while IFS= read -r snippet; do
      if printf %s\\n "$snippet" | grep -qE 'mg.sh$'; then
        "${MG_ROOTDIR%/}/bin/pack.sh" -o -
      else
        cat "$snippet"
      fi
    done
}

MAKER_OUTPUT=
if [ "$#" -gt "0" ]; then
  MAKER_OUTPUT="$1"
fi

if [ "$MAKER_OUTPUT" = "-" ] || [ -z "$MAKER_OUTPUT" ]; then
  dump
elif [ -f "$MAKER_OUTPUT" ] && [ "$MAKER_OVERRIDE" = "1" ]; then
  dump > "$MAKER_OUTPUT"
  chmod a+x "$MAKER_OUTPUT"
elif ! [ -f "$MAKER_OUTPUT" ]; then
  dump > "$MAKER_OUTPUT"
  chmod a+x "$MAKER_OUTPUT"
else
  echo "File at $MAKER_OUTPUT already exists!" >& 2
  exit 1
fi
