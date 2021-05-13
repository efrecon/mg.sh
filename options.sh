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
if ! printf %s\\n "${MG_MODULES:-}"|grep -q "controls"; then
  die "This module requires the controls module"
fi

parseopts() {
  stack_let prefix
  stack_let options
  stack_let marker
  stack_let line
  stack_let names
  stack_let type
  stack_let varname
  stack_let default
  stack_let text

  # Has to be separate to avoid stack_let bug
  marker=-

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
    stack_let l_nm

    OIFS=$IFS
    IFS=,; for nm in $(printf %s\\n "$2"); do
      l_nm=$(printf %s "${nm##-}" | wc -c); # No \n otherwise 1 char too long!
      if [ "${1##-}" = "${nm##-}" ] && \
          [ "$l_nm" -ge "${3:-0}" ] && \
          [ "$l_nm" -le "${4:-999}" ]; then
        printf %s\\n "${nm##-}"
      fi
    done
    IFS=$OIFS
    stack_unlet nm
    stack_unlet l_nm
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

  _help() {
    # Avoid polluting main variables, add a stack!
    stack_let line
    stack_let names
    stack_let type
    stack_let varname
    stack_let default
    stack_let text

    # FIXME: output to stderr by default, or what log module uses?
    printf "OPTIONS:\n"
    printf "\n"
    while IFS="$(printf '\n')" read -r line; do
      if [ -n "$line" ]; then
        _fields "$line"; # Sets: names, type, varname, default and text
        # FIXME: add single or double dash, remove commas
        printf "  %s\n" "$names"
        # FIXME: Wrap at 80 columns.
        printf "    %s\n" "$text"
      fi
    done <<EOF
$(printf %s\\n "$options"|sort)
EOF
    printf "\n"
    stack_unlet line names type varname default text
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

      -m | --marker)
        marker=$2; shift 2;;

      --)
        shift; break;;

      *)
        break;;
    esac
  done

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
          log_error "$1 is an unknown option"
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
                      log_error "Value in flag $1 not a recognised boolean!";;
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
          log_error "$opt is an unknown option"
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
          log_error "$1 is an unknown option"
          break
        fi
        ;;
      -*)
        log_error "$1 is an unknown option"
        break;;
      *)
        break;;
    esac
  done

  stack_unlet line names type varname default text
  stack_unlet prefix options marker
}