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

module locals log options controls filesystem portability text interaction date

# Prefer internal implementation when it exists!
if is_function "mg_$MG_APPNAME"; then
  "mg_$MG_APPNAME" "$@"
elif is_function "$MG_APPNAME"; then
  "$MG_APPNAME" "$@"
else
  fn=$1; shift
  if is_function "mg_$fn"; then
    "mg_$fn" "$@"
  elif is_function "$fn"; then
    "$fn" "$@"
  else
    die "Neither $MG_APPNAME nor $fn are functions of the mg.sh API"
  fi
fi
