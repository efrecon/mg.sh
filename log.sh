#!/bin/sh

# When run at the terminal, the default is to set MG_INTERACTIVE to be 1,
# turning on colouring for all calls to the colouring functions contained here.
if [ -t 1 ]; then
  : "${MG_INTERACTIVE:=1}"
else
  : "${MG_INTERACTIVE:=0}"
fi

# Verbosity inside the script. One of: error, warn, notice, info, debug or
# trace.
: "${MG_VERBOSITY:="info"}"

# Store the root directory where the script was found, together with the name of
# the script and the name of the app, e.g. the name of the script without the
# extension.
# shellcheck disable=2034 # Declare this so it can be used in scripts
MG_APPDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
MG_CMDNAME=$(basename -- "$0")
MG_APPNAME=${MG_CMDNAME%.*}

# This should be set from the script with a usage description that will be print
# out from the usage procedure when problems are detected.
: "${MG_USAGE:=""}"

# Colourisation support for logging and output.
_colour() {
  if [ "$MG_INTERACTIVE" = "1" ]; then
    # shellcheck disable=SC2086
    printf '\033[1;31;'${1}'m%b\033[0m' "$2"
  else
    printf -- "%b" "$2"
  fi
}
green() { _colour "32" "$1"; }
red() { _colour "31" "$1"; }
yellow() { _colour "33" "$1"; }
blue() { _colour "34" "$1"; }
magenta() { _colour "35" "$1"; }
cyan() { _colour "36" "$1"; }
dark_gray() { _colour "90" "$1"; }
light_gray() { _colour "37" "$1"; }


# Convert textual log levels to numbers for comparison.
_log_level() {
  case "$1" in
    [Ee][Rr][Rr][Oo][Rr])
      printf 1\\n;;
    [Ww][Aa][Rr][Nn])
      printf 2\\n;;
    [Nn][Oo][Tt][Ii][Cc][Ee])
      printf 3\\n;;
    [Ii][Nn][Ff][Oo])
      printf 4\\n;;
    [Dd][Ee][Bb][Uu][Gg])
      printf 5\\n;;
    [Tt][Rr][Aa][Cc][Ee])
      printf 6\\n;;
    [0-9])
      printf %d\\n "$1";;
    *)
      printf 3\\n;;
  esac
}


# Conditional coloured logging
_log() (
  if [ "$(_log_level "$1")" -le "$(_log_level "$MG_VERBOSITY")" ]; then
    case "$1" in
      [Ee][Rr][Rr][Oo][Rr])
        printf "[%s] [%s] [%s] %s\n" "$(dark_gray "$3")" "$(magenta ERR)" "$(date +'%Y%m%d-%H%M%S')" "$2" >&2;;
      [Ww][Aa][Rr][Nn])
        printf "[%s] [%s] [%s] %s\n" "$(dark_gray "$3")" "$(red WRN)" "$(date +'%Y%m%d-%H%M%S')" "$2" >&2;;
      [Nn][Oo][Tt][Ii][Cc][Ee])
        printf "[%s] [%s] [%s] %s\n" "$(dark_gray "$3")" "$(yellow NTC)" "$(date +'%Y%m%d-%H%M%S')" "$2" >&2;;
      [Ii][Nn][Ff][Oo])
        printf "[%s] [%s] [%s] %s\n" "$(dark_gray "$3")" "$(blue INF)" "$(date +'%Y%m%d-%H%M%S')" "$2" >&2;;
      [Dd][Ee][Bb][Uu][Gg])
        printf "[%s] [%s] [%s] %s\n" "$(dark_gray "$3")" "$(light_gray DBG)" "$(date +'%Y%m%d-%H%M%S')" "$2" >&2;;
      [Tt][Rr][Aa][Cc][Ee])
        printf "[%s] [%s] [%s] %s\n" "$(dark_gray "$3")" "$(dark_gray TRC)" "$(date +'%Y%m%d-%H%M%S')" "$2" >&2;;
      *)
        printf "[%s] [%s] [%s] %s\n" "$(dark_gray "$3")" "log" "$(date +'%Y%m%d-%H%M%S')" "$2" >&2;;
    esac
  fi
)
log_error() { _log error "$1" "${2:-$MG_APPNAME}"; }
log_warn() { _log warn "$1" "${2:-$MG_APPNAME}"; }
log_notice() { _log notice "$1" "${2:-$MG_APPNAME}"; }
log_info() { _log info "$1" "${2:-$MG_APPNAME}"; }
log_debug() { _log debug "$1" "${2:-$MG_APPNAME}"; }
log_trace() { _log trace "$1" "${2:-$MG_APPNAME}"; }
log() { log_info "$@"; } # For the lazy ones...
die() { [ -n "${1:-}" ] && log_error "$1"; exit "${2:-1}"; }

check_verbosity() {
  printf %s\\n "error
warn
notice
info
debug
trace" | grep -qi "${1:-$MG_VERBOSITY}"
}

at_verbosity() {
  test "$(_log_level "$1")" -le "$(_log_level "$MG_VERBOSITY")"
}

usage() {
  [ "$#" -gt "1" ] && printf %s\\n "$2" >&2
  if [ -z "$MG_USAGE" ]; then
    printf %s\\n "$MG_CMDNAME was called with erroneous options!" >&2
  else
    printf %s\\n "$MG_USAGE" >&2
  fi
  exit "${1:-1}"
}