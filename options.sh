#!/usr/bin/env sh

# Protect against double loading and register dependencies
if printf %s\\n "${MG_MODULES:-}"|grep -q "options"; then
  return
else
  MG_MODULES="${MG_MODULES:-} options"
fi

if ! printf %s\\n "${MG_MODULES:-}"|grep -q "log"; then
  printf %s\\n "This module requires the log module" >&2
fi
if ! printf %s\\n "${MG_MODULES:-}"|grep -q "locals"; then
  die "This module requires the locals module"
fi

# Example call:
# parseopts \
#   --prefix TOPT \
#   --options \
#       h,help FLAG @HELP - "Gives this very long help to test if we properly wrap text when outputing stuff and exit" \
#       s,sleep,wait OPTION WAIT 10 "How long to wait" \
#       trigger OPTION @callback 46 "Generate a callback" \
#   --main \
#   -- "$@"
parseopts() {
  stack_let prefix
  stack_let options
  stack_let marker "-"
  stack_let main 0
  stack_let wrap 80
  stack_let summary ""
  stack_let description ""

  _quote() {
    if [ -z "$1" ]; then
      printf "\"%s\"\n" "$1"
    else
      printf "%s\n" "$1"
    fi
  }

  _unquote() {
    printf %s\\n "$1" | sed -E -e 's/^"//' -e 's/"$//'
  }

  _find() {
    stack_let nm

    OIFS=$IFS
    IFS=,; for nm in $(printf %s\\n "$2"); do
      nm=${nm##-}
      if [ "${1##-}" = "$nm" ] && \
          [ "${#nm}" -ge "${3:-0}" ] && \
          [ "${#nm}" -le "${4:-999}" ]; then
        printf %s\\n "$nm"
      fi
    done
    IFS=$OIFS
    stack_unlet nm
  }

  _toupper() {
    printf %s\\n "$1" | tr '[:lower:]' '[:upper:]'
  }

  _tolower() {
    printf %s\\n "$1" | tr '[:upper:]' '[:lower:]'
  }

  _fields() {
    IFS="$(printf '\t')" read -r names type varname default text <<EOF
$(printf %s\\n "$1")
EOF
    varname=$(_unquote "$varname")
    default=$(_unquote "$default")
    text=$(_unquote "$text")
  }

  _critical() {
    if [ "$main" = "1" ]; then
      die "$1"
    else
      log_error "$1"
    fi
  }

  _print_opt_list() {
    stack_let nm
    stack_let first 1

    # Leading indentation
    printf "%s" "${2:-}"
    OIFS=$IFS
    IFS=,; for nm in $(printf %s\\n "$1"); do
      nm="${nm##-}"
      [ "$first" = "0" ] && printf "| "
      first=0
      if [ "${#nm}" = "1" ]; then
        #shellcheck disable=SC3045 # We want to print the dash!
        printf '%s%s' "-" "$nm"
      else
        #shellcheck disable=SC3045 # We want to print the dash!
        printf '%s%s' "--" "$nm"
      fi
    done
    IFS=$OIFS
    stack_unlet nm first
    printf \\n
  }

  _wrap() {
    stack_let max
    stack_let l_indent

    #shellcheck disable=SC2034 # We USE l_indent to compute wrapping max!
    l_lindent=${#1}
    #shellcheck disable=SC2154 # We USE l_indent to compute wrapping max!
    max=$((wrap - l_indent))
    printf "%s\n" "$2" |fold -s -w "$max"|sed -E "s/^(.*)$/$1\\1/g"
    stack_unlet max l_indent
  }

  _help() {
    # Avoid polluting main variables, add a stack!
    stack_let line
    stack_let names
    stack_let type
    stack_let varname
    stack_let default
    stack_let text

    if [ -n "$summary" ]; then
      _wrap "  " "$summary" >&2
      printf "\n" >&2
    fi
    printf "OPTIONS:\n" >&2
    while IFS="$(printf '\n')" read -r line; do
      if [ -n "$line" ]; then
        _fields "$line"; # Sets: names, type, varname, default and text
        _print_opt_list "$names" "  " >&2
        _wrap "    " "$text">&2
      fi
    done <<EOF
$(printf %s\\n "$options"|sort)
EOF
    printf "\n" >&2
    if [ -n "$description" ]; then
      printf "DESCRIPTION:\n" >&2
      _wrap "  " "$description" >&2
      printf "\n" >&2
    fi
    stack_unlet line names type varname default text
    [ "$main" = "1" ] && die
  }

  _setvar() {
    if [ -n "$1" ] && [ "$1" != "$marker" ]; then
      if [ -n "$2" ]; then
        eval "$(printf "%s=%s" "${2%_}_${1#_}" "$3")"
      else
        eval "$(printf "%s=%s" "$2" "$3")"
      fi
    fi
  }

  _trigger() {
    if [ "$(printf %s\\n "$2"|cut -c 1)" = "@" ]; then
      stack_let cb
      cb=$(printf %s\\n "$2"|cut -c 2-)
      if [ "$cb" = "HELP" ]; then
        _help
      else
        "$cb" "$1" "$4"
      fi
      stack_unlet cb
    else
      _setvar "$2" "$3" "$4"
    fi
  }

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -p | --prefix)
        prefix=$2; shift 2;;

      -o | --options | --opts)
        shift;
        while [ "${1#-}" = "$1" ]; do
          # Check params and scream?
          options="$(printf \
                          "%s\t%s\t%s\t%s\t%s" \
                            "$1" \
                            "$2" \
                            "$(_quote "$3")" \
                            "$(_quote "$4")" \
                            "$(_quote "$5")")
$options"
          shift 5;
        done
        ;;

      -k | --marker)
        marker=$2; shift 2;;

      -m | --main)
        main=1; shift;;

      -w | --wrap)
        wrap=$2; shift 2;;

      -s | --summary)
        summary=$2; shift 2;;

      -d | --description)
        description=$2; shift 2;;

      --)
        shift; break;;

      *)
        break;;
    esac
  done

  stack_let line
  stack_let names
  stack_let type
  stack_let varname
  stack_let default
  stack_let text

  # Set defaults
  while IFS="$(printf '\n')" read -r line; do
    if [ -n "$line" ]; then
      _fields "$line"; # Sets: names, type, varname, default and text
      if [ "$default" != "$marker" ]; then
        _trigger \
            "$(printf %s\\n "$names" | cut -d , -f 1)" \
            "$varname" \
            "$prefix" \
            "$default"
      fi
    fi
  done <<EOF
$(printf %s\\n "$options")
EOF

  while [ $# -gt 0 ]; do
    case "$1" in
      -[a-zA-Z0-9])
        found=
        while IFS="$(printf '\n')" read -r line; do
          if [ -n "$line" ]; then
            _fields "$line"; # Sets: names, type, varname, default and text

            candidate=$(_find "$1" "$names" 1 1)
            if [ -n "$candidate" ]; then
              case "$(_toupper "$type")" in
                FLAG)
                  _trigger "$candidate" "$varname" "$prefix" "1"
                  found=$candidate
                  shift
                  break;;
                OPT*)
                  _trigger "$candidate" "$varname" "$prefix" "$2"
                  found=$candidate
                  shift 2
                  break;;
              esac
            fi
          fi
        done <<EOF
$(printf %s\\n "$options")
EOF
        if [ -z "$found" ]; then
          _critical "$1 is an unknown option"
          break
        fi
        ;;
      --*=*)
        found=
        while IFS="$(printf '\n')" read -r line; do
          if [ -n "$line" ]; then
            _fields "$line"; # Sets: names, type, varname, default and text

            opt="${1%=*}"; opt="${opt#--}"
            val="${1#*=}"
            candidate=$(_find "$opt" "$names" 2)
            if [ -n "$candidate" ]; then
              case "$(_toupper "$type")" in
                FLAG)
                  case "$(_tolower "$val")" in
                    true | on | yes | 1)
                      _trigger "$candidate" "$varname" "$prefix" "1"
                      found=$candidate;;
                    false | off | no | 0)
                      _trigger "$candidate" "$varname" "$prefix" "0"
                      found=$candidate;;
                    *)
                      _critical "Value in flag $1 not a recognised boolean!";;
                  esac
                  shift
                  break
                  ;;
                OPT*)
                  _trigger "$candidate" "$varname" "$prefix" "$val"
                  found=$candidate
                  shift
                  break;;
              esac
            fi
          fi
        done <<EOF
$(printf %s\\n "$options")
EOF
        if [ -z "$found" ]; then
          _critical "$opt is an unknown option"
          break
        fi
        ;;
      --*)
        found=
        while IFS="$(printf '\n')" read -r line; do
          if [ -n "$line" ]; then
            _fields "$line"; # Sets: names, type, varname, default and text

            candidate=$(_find "${1#--}" "$names" 2)
            if [ -n "$candidate" ]; then
              case "$(_toupper "$type")" in
                FLAG)
                  _trigger "$candidate" "$varname" "$prefix" "1"
                  found=$candidate
                  shift
                  break;;
                OPT*)
                  _trigger "$candidate" "$varname" "$prefix" "$2"
                  found=$candidate
                  shift 2
                  break;;
              esac
            fi
          fi
        done <<EOF
$(printf %s\\n "$options")
EOF
        if [ -z "$found" ]; then
          _critical "$1 is an unknown option"
          break
        fi
        ;;
      -*)
        _critical "$1 is an unknown option"
        break;;
      *)
        break;;
    esac
  done

  stack_unlet line names type varname default text
  stack_unlet prefix options marker wrap summary description
}