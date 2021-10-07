#!/bin/sh

module locals

# The functions below originally appeared in the MIT-licensed yu.sh. They have
# been modernised.

# Return the approx. number of seconds for the human-readable period passed as a
# parameter
howlong() {
  stack_let len
  if printf %s\\n "$1"|grep -Eqo '^[0-9]+[[:space:]]*[yY]'; then
    len=$(printf %s\\n "$1"  | sed -En 's/([0-9]+)[[:space:]]*[yY].*/\1/p')
    # shellcheck disable=SC2003
    expr "$len" \* 31536000
  elif printf %s\\n "$1"|grep -Eqo '^[0-9]+[[:space:]]*[Mm][Oo]'; then
    len=$(printf %s\\n "$1"  | sed -En 's/([0-9]+)[[:space:]]*[Mm][Oo].*/\1/p')
    # shellcheck disable=SC2003
    expr "$len" \* 2592000
  elif printf %s\\n "$1"|grep -Eqo '^[0-9]+[[:space:]]*[Mm][Ii]'; then
    len=$(printf %s\\n "$1"  | sed -En 's/([0-9]+)[[:space:]]*[Mm][Ii].*/\1/p')
    # shellcheck disable=SC2003
    expr "$len" \* 60
  elif printf %s\\n "$1"|grep -Eqo '^[0-9]+[[:space:]]*m'; then
    len=$(printf %s\\n "$1"  | sed -En 's/([0-9]+)[[:space:]]*m.*/\1/p')
    # shellcheck disable=SC2003
    expr "$len" \* 2592000
  elif printf %s\\n "$1"|grep -Eqo '^[0-9]+[[:space:]]*[Ww]'; then
    len=$(printf %s\\n "$1"  | sed -En 's/([0-9]+)[[:space:]]*[Ww].*/\1/p')
    # shellcheck disable=SC2003
    expr "$len" \* 604800
  elif printf %s\\n "$1"|grep -Eqo '^[0-9]+[[:space:]]*[Dd]'; then
    len=$(printf %s\\n "$1"  | sed -En 's/([0-9]+)[[:space:]]*[Dd].*/\1/p')
    # shellcheck disable=SC2003
    expr "$len" \* 86400
  elif printf %s\\n "$1"|grep -Eqo '^[0-9]+[[:space:]]*[Hh]'; then
    len=$(printf %s\\n "$1"  | sed -En 's/([0-9]+)[[:space:]]*[Hh].*/\1/p')
    # shellcheck disable=SC2003
    expr "$len" \* 3600
  elif printf %s\\n "$1"|grep -Eqo '^[0-9]+[[:space:]]*M'; then
    len=$(printf %s\\n "$1"  | sed -En 's/([0-9]+)[[:space:]]*M.*/\1/p')
    # shellcheck disable=SC2003
    expr "$len" \* 60
  elif printf %s\\n "$1"|grep -Eqo '^[0-9]+[[:space:]]*[Ss]'; then
    len=$(printf %s\\n "$1"  | sed -En 's/([0-9]+)[[:space:]]*[Ss].*/\1/p')
    echo "$len"
  elif printf %s\\n "$1"|grep -Eqo '^[0-9]+'; then
    printf %s\\n "$1"
  fi
  stack_unlet len
}

# Convert a number of seconds to a human-friendly string mentioning days, hours,
# etc.
human_period() {
  stack_let in="$1"
  stack_let out=""
  # shellcheck disable=SC2154  # Local through stack_let
  stack_let d=$((in/60/60/24))
  stack_let h=$((in/60/60%24))
  stack_let m=$((in/60%60))
  stack_let s=$((in%60))

  # shellcheck disable=SC2154  # Local through stack_let
  if [ "$d" -gt "0" ]; then
    [ "$d" = "1" ] && out="$(printf "%s%d day " "$out" "$d")" || out="$(printf "%s%d days " "$out" "$d")"
  fi
  # shellcheck disable=SC2154  # Local through stack_let
  if [ "$h" -gt 0 ]; then
    [ "$h" = "1" ] && out="$(printf "%s%d hour " "$out" "$h")" || out="$(printf "%s%d hours " "$out" "$h")"
  fi
  # shellcheck disable=SC2154  # Local through stack_let
  if [ "$m" -gt "0" ]; then
    [ "$m" = "1" ] && out="$(printf "%s%d minute " "$out" "$m")" || out="$(printf "%s%d minutes " "$out" "$m")"
  fi
  # shellcheck disable=SC2154  # Local through stack_let
  if [ "$d" = "0" ] && [ "$h" = "0" ] && [ "$m" = "0" ]; then
    [ "$s" = "1" ] && out="$(printf "%s%d second " "$out" "$s")" || out="$(printf "%s%d seconds " "$out" "$s")"
  fi
  printf %s\\n "${out% }"
  stack_unlet in,out,d,h,m,s
}


# Returns the number of seconds since the epoch for the ISO8601 date passed as
# an argument. This will only recognise a subset of the standard, i.e. dates
# with milliseconds, microseconds, nanoseconds or none specified, and timezone
# only specified as diffs from UTC, e.g. 2019-09-09T08:40:39.505-07:00 or
# 2019-09-09T08:40:39.505214+00:00. The special Z timezone (i.e. UTC) is also
# recognised. The implementation actually computes the ms/us/ns whenever they
# are available, but discards them.
iso8601() {
  stack_let ds
  stack_let tz
  stack_let tzdiff
  stack_let secs
  stack_let utc

  # Arrange for ns to be the number of nanoseconds.
  ds=$(printf %s\\n "$1"|sed -E 's/([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})(\.([0-9]{3,9}))?([+-]([0-9]{2}):([0-9]{2})|Z)?/\8/')
  # ns=0
  if [ -n "$ds" ]; then
    if [ "${#ds}" = "10" ]; then
      ds=$(printf %s\\n "$ds" | sed 's/^0*//')
      # ns=$ds
    elif [ "${#ds}" = "7" ]; then
      ds=$(printf %s\\n "$ds" | sed 's/^0*//')
      # ns=$((1000*ds))
    else
      ds=$(printf %s\\n "$ds" | sed 's/^0*//')
      # ns=$((1000000*ds))
    fi
  fi


  # Arrange for tzdiff to be the number of seconds for the timezone.
  tz=$(printf %s\\n "$1"|sed -E 's/([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})(\.([0-9]{3,9}))?([+-]([0-9]{2}):([0-9]{2})|Z)?/\9/')
  tzdiff=0
  if [ -n "$tz" ]; then
    if [ "$tz" = "Z" ]; then
      tzdiff=0
    else
      stack_let hrs
      stack_let mns
      stack_let sign

      hrs=$(printf %s\\n "$tz" | sed -E 's/[+-]([0-9]{2}):([0-9]{2})/\1/')
      mns=$(printf %s\\n "$tz" | sed -E 's/[+-]([0-9]{2}):([0-9]{2})/\2/')
      hrs=${hrs##0}; mns=${mns##0};   # Strip leading 0s
      sign=$(printf %s\\n "$tz" | sed -E 's/([+-])([0-9]{2}):([0-9]{2})/\1/')
      secs=$((hrs*3600+mns*60))
      if [ "$sign" = "-" ]; then
        tzdiff=$secs
      else
        tzdiff=$((-secs))
      fi
      stack_unlet hrs mns sign
    fi
  fi

  # Extract UTC date and time into something that date can understand, then
  # add the number of seconds representing the timezone.
  utc=$(printf %s\\n "$1"|sed -E 's/([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})(\.([0-9]{3,9}))?([+-]([0-9]{2}):([0-9]{2})|Z)?/\1-\2-\3 \4:\5:\6/')
  if [ "$(uname -s)" = "Darwin" ]; then
    secs=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$utc" +"%s")
  else
    secs=$(date -u -d "$utc" +"%s")
  fi
  # shellcheck disable=SC2003
  expr "$secs" + \( "$tzdiff" \)

  stack_unlet ds tz tzdiff secs utc
}
