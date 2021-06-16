#!/usr/bin/env sh

# Protect against double loading and register dependencies
if printf %s\\n "${MG_MODULES:-}"|grep -q "filesystem"; then
  return
else
  MG_MODULES="${MG_MODULES:-} filesystem"
fi

is_abspath() {
  case "$1" in
    /* | ~*) true;;
    *) false;;
  esac
}
