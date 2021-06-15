#!/usr/bin/env sh

# Protect against double loading and register dependencies
if printf %s\\n "${MG_MODULES:-}"|grep -q "controls"; then
  return
else
  MG_MODULES="${MG_MODULES:-} controls"
fi

if ! printf %s\\n "${MG_MODULES:-}"|grep -q "locals"; then
  printf %s\\n "This module requires the locals module" >&2
fi

backoff_loop() {
  # Default when nothing is specified is to loop forever every second.

  # All variables are declared local so that recursive calls are possible.
  stack_let _wait=1
  stack_let _max=
  stack_let _mult=
  stack_let _timeout=

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
        -l | --loop)
          _wait=$(printf %s\\n "$2" | awk -F: '{print $1}')
          _max=$(printf %s\\n "$2" | awk -F: '{print $2}')
          _mult=$(printf %s\\n "$2" | awk -F: '{print $3}')
          _timeout=$(printf %s\\n "$2" | awk -F: '{print $4}')
          shift 2;;
        --loop=*)
          _wait=$(printf %s\\n "${1#*=}" | awk -F: '{print $1}')
          _max=$(printf %s\\n "${1#*=}" | awk -F: '{print $2}')
          _mult=$(printf %s\\n "${1#*=}" | awk -F: '{print $3}')
          _timeout=$(printf %s\\n "${1#*=}" | awk -F: '{print $4}')
          shift;;
        -s | --sleep)
          _wait=$2; shift 2;;
        --sleep=*)
          _wait=${1#*=}; shift;;
        -m | --max | --maximum)
          _max=$2; shift 2;;
        --max=* | --maximum=*)
          _max=${1#*=}; shift;;
        -f | --factor | --multiplier)
          _mult=$2; shift 2;;
        --factor=* | --multiplier=*)
          _mult=${1#*=}; shift;;
        -t | --timeout)
          _timeout=$2; shift 2;;
        --timeout=*)
          _timeout=${1#*=}; shift;;
        --)
          shift; break;;
        -*)
          log_warn "$1 Unknown option!"
          return 1;;
        *)
          break;;
    esac
  done

  # Check arguments for sanity
  if [ -n "$_wait" ] && ! printf %s\\n "$_wait" | grep -q '[0-9]'; then
    log_warn "(Initial) waiting time $_wait not an integer!"; return 1
  fi
  if [ -n "$_max" ] && ! printf %s\\n "$_max" | grep -q '[0-9]'; then
    log_warn "Maximum waiting time $_max not an integer!"; return 1
  fi
  if [ -n "$_mult" ] && ! printf %s\\n "$_mult" | grep -q '[0-9]'; then
    log_warn "Multiplication factor $_mult not an integer!"; return 1
  fi
  if [ -n "$_timeout" ] && ! printf %s\\n "$_timeout" | grep -q '[0-9]'; then
    log_warn "Timeout $_timeout not an integer!"; return 1
  fi

  if [ -z "$_wait" ]; then
    log_warn "You must at least specify a waiting time!"; return 1
  fi
  if [ -n "$_wait" ] && [ "$_wait" -le 0 ]; then
    log_warn "(Initial) waiting time $_wait must be a positive integer!"; return 1
  fi
  if [ -n "$_max" ] && [ "$_max" -le 0 ]; then
    log_warn "Maximum waiting time $_max must be a positive integer!"; return 1
  fi
  if [ -n "$_mult" ] && [ "$_mult" -le 0 ]; then
    log_warn "Multiplication factor $_mult must be a positive integer!"; return 1
  fi
  if [ -n "$_timeout" ] && [ "$_timeout" -le 0 ]; then
    log_warn "Timeout $_timeout must be a positive integer!"; return 1
  fi

  # Good defaults
  [ -z "$_mult" ] && _mult=2;   # Default multiplier is 2

  stack_let _waited=0
  while true; do
    # Execute the command and if it returns true, we are done and will exit
    # after cleanup.
    if "$@"; then
      break
    fi

    # Sleep for the initial period
    sleep "$_wait"

    # Timeout reached. We return
    _waited=$(( _waited + _wait))
    if [ -n "$_timeout" ] && [ "$_waited" -ge "$_timeout" ]; then
      break;
    fi

    # If there is no max value we default to waiting the same amount of seconds
    # each time. Otherwise, we use the colon-separated fields to perform
    # exponential backoff and try connecting as soon as possible without too
    # much burden on the DB server.
    if [ -n "$_max" ]; then
      _wait=$(( _wait * _mult ))
      if [ "$_wait" -gt "$_max" ]; then
        _wait=$_max
      fi
    fi
  done

  # Cleanup and exit
  stack_unlet _wait _max _mult _timeout _waited
}

var_exists() { eval "[ -n \"\$${1:-}\" ]"; }