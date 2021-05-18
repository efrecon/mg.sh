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
  stack_let prefix=
  stack_let options=
  stack_let marker="-"
  stack_let main=0
  stack_let wrap=80
  stack_let synopsis=
  stack_let description=
  stack_let usage=
  stack_let terminator=1
  stack_let reportvar=
  stack_let parsed=0

  # Insert double-quotes around the first parameter if it is an empty string,
  # none otherwise. Then return it.
  _quote() {
    if [ -z "${1:-}" ]; then
      printf "\"%s\"\n" "${1:-}"
    else
      printf "%s\n" "$1"
    fi
  }

  # Remove leading and ending double-quotes from the string passed as a
  # parameter and return it.
  _unquote() {
    printf %s\\n "$1" | sed -E -e 's/^"//' -e 's/"$//'
  }

  # Detect if $2 exists in the comma separated list of tokens passed as $1.
  # Detection is caseless.
  _has() {
    printf %s\\n "$2" | grep -qiE "(^|,)${1}(,|\$)"
  }

  # Find the option $1 in the comma separated list of options passed as $2.
  # Options are case-sensitive, but equality will trigger on option strings that
  # are cleaned from all leading dashes. When $3 and $4 are present, they should
  # be integers min and max lengths for the tokens in the list passed in $2.
  _find() {
    stack_let nm=

    OIFS=$IFS
    IFS=,; for nm in $(printf %s\\n "$2"); do
      nm=${nm##+(-)}
      if [ "${1##+(-)}" = "$nm" ] && \
          [ "${#nm}" -ge "${3:-0}" ] && \
          [ "${#nm}" -le "${4:-999}" ]; then
        printf %s\\n "$nm"
      fi
    done
    IFS=$OIFS
    stack_unlet nm
  }

  # Convert the string passed as a parameter to uppercase
  _toupper() {
    printf %s\\n "$1" | tr '[:lower:]' '[:upper:]'
  }

  # Convert the string passed as a parameter to lowercase
  _tolower() {
    printf %s\\n "$1" | tr '[:upper:]' '[:lower:]'
  }

  # Provided the argument $1 is a list of tab-separated tokens, isolate exactly
  # 5 of these tokens in the variables names, type, varname, default and text.
  # The last three of these variables are automatically unquoted (see
  # _unquote())
  _fields() {
    IFS="$(printf '\t')" read -r names type varname default text <<EOF
$(printf %s\\n "$1")
EOF
    varname=$(_unquote "$varname")
    default=$(_unquote "$default")
    text=$(_unquote "$text")
  }

  # Generate a critical error with the message string passed as an argument.
  # When the variable $main is set to 1, this will use the log module to produce
  # an error and end the script. Otherwise, an error message will be generated.
  _critical() {
    if [ "$main" = "1" ]; then
      die "$1"
    else
      log_error "$1"
    fi
  }

  # When the section description passed in $2 is not empty, print out a section
  # of the help using the title in $2 in uppercase, and the text passed as $1,
  # wrapped at the maximum output column. The section description is indented
  # with 2 spaces to ease reading.
  _section() {
    if [ -n "$2" ]; then
      printf "\n" >&2
      [ -n "$1" ] && printf "%s\n" "$(_toupper "$1")" >&2
      _wrap "  " "$2" >&2
    fi
  }

  # Given a comma separated list of options, nicely print them out after having
  # removed any leading dash. Single-letter options will always have a
  # single-dash, longer options a double-dash. Output is indented using the
  # string in $2.
  _print_opt_list() {
    stack_let nm=
    stack_let first=1

    # Leading indentation
    printf "%s" "${2:-}"
    OIFS=$IFS
    IFS=,; for nm in $(printf %s\\n "$1"); do
      nm="${nm##+(-)}"
      [ "$first" = "0" ] && printf " | "
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

  # Wrap the text passed in $1, indented with the string passed in $2. Wrapping
  # happens at the column $wrap.
  _wrap() {
    stack_let max=
    stack_let l_indent=

    #shellcheck disable=SC2034 # We USE l_indent to compute wrapping max!
    l_lindent=${#1}
    #shellcheck disable=SC2154 # We USE l_indent to compute wrapping max!
    max=$((wrap - l_indent))
    printf "%s\n" "$2" |fold -s -w "$max"|sed -E "s/^(.*)$/$1\\1/g"
    stack_unlet max l_indent
  }

  # Provided an internal, tab-separated token representation of the options
  # contained in $options, output generic help. The help uses indentation to
  # improve reading, and will automatically wrap long text at column $wrap.
  # Output consists of a synopsis, a usage and a description of the options, and
  # finally a generic description. The $synopsis, $usage and $description will
  # only be output when the strings are not empty. When options are described,
  # defaults for the option will automatically be appended to the option text.
  _help() {
    # Avoid polluting main variables, add a stack!
    stack_let line=
    stack_let names=
    stack_let type=
    stack_let varname=
    stack_let default=
    stack_let text=
    stack_let defvar=

    _section "" "$synopsis"
    _section "usage" "$usage"
    printf "\n" >&2
    printf "OPTIONS:\n" >&2
    while IFS="$(printf '\n')" read -r line; do
      if [ -n "$line" ]; then
        _fields "$line"; # Sets: names, type, varname, default and text
        _print_opt_list "$names" "  " >&2
        defvar=$(_dstvar)
        if [ -n "$defvar" ]; then
          if set | grep -q "^${defvar}="; then
            _wrap "    " "$text (default: $(set | grep "^${defvar}=" |sed -E "s/^${defvar}=(.*)\$/\1/"))" >&2
          elif [ -n "$default" ]; then
            _wrap "    " "$text (default: $default)">&2
          fi
        else
          _wrap "    " "$text">&2
        fi
      fi
    done <<EOF
$(printf %s\\n "$options"|sort)
EOF
    printf "\n" >&2
    _section "description" "$description"
    printf "\n" >&2
    stack_unlet line names type varname default text defvar
    if [ "$main" = "1" ] && [ "${1:-1}" = "1" ]; then
      die
    fi
  }

  # Whenever the raw variable name passed in $1 is nor empty, nor equal to the
  # $marker (usually a dash), this will set the variable formed out of the
  # prefix passed as $2 (if any) and the raw name passed as $1 to the value
  # passed as $3. When the prefix is non-empty, it will be joined to the raw
  # variable name using an underscore.
  _setvar() {
    if [ -n "$1" ] && [ "$1" != "$marker" ]; then
      stack_let thevar=
      if [ -n "$2" ]; then
        thevar=${2%_}_${1#_}
      else
        thevar=$1
      fi
      log_trace "Setting $thevar to $3"
      eval "$thevar='$3'"
      stack_unlet thevar
    fi
  }

  # Provided the raw variable name in $varname, the "do not set variable" marker
  # in $marker, the flags and type list in $type and the prefix in $prefix,
  # return the underscore joined full variable name to set, whenever relevant.
  # Otherwise, an empty string.
  _dstvar() {
    if [ "$(printf %s\\n "$varname"|cut -c 1)" != "@" ] \
          && [ -n "$varname" ] \
          && [ "$varname" != "$marker" ]; then
      if _has NOPREFIX "$type"; then
        printf "%s\\n" "${varname}"
      else
        printf "%s_%s\\n" "${prefix%_}" "${varname#_}"
      fi
    fi
  }

  # Provided the raw variable name in $varname and the prefix in $prefix, this
  # will trigger or set the variable. The option that triggered the action
  # should be passed (without leading dashes) in $1 and the value (for the
  # trigger or the variable) passed in $2.
  _trigger() {
    if [ "$(printf %s\\n "$varname"|cut -c 1)" = "@" ]; then
      # When the variable name starts with an arobas, this is a trigger.
      # Internal triggers are in uppercase and implemented directly here,
      # otherwise the trigger is a function which name is after the leading
      # arobase and the function is triggered from here.
      stack_let cb=
      cb=$(printf %s\\n "$varname"|cut -c 2-)
      if [ "$cb" = "HELP" ]; then
        _help
      else
        log_trace "Triggering $cb with option name $1 and value $2"
        "$cb" "$1" "$2"
      fi
      stack_unlet cb
    else
      # Set the destination variable. Whenever the NOPREFIX is found in $type,
      # no prefix will be appended. Otherwise, the prefix will be appended to
      # the name of the variable if it is set.
      if _has NOPREFIX "$type"; then
        _setvar "$varname" "" "$2"
      else
        _setvar "$varname" "$prefix" "$2"
      fi
    fi
  }

  # Parse options of function itself
  log_trace "Parsing options to function"
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

      --no-terminator)
        terminator=0; shift;;

      --shift | --end)
        reportvar=$2; shift 2;;

      -w | --wrap)
        wrap=$2; shift 2;;

      -s | --synopsis)
        synopsis=$2; shift 2;;

      -d | --description)
        description=$2; shift 2;;

      -u | --usage)
        usage=$2; shift 2;;

      --)
        shift; break;;

      *)
        break;;
    esac
  done

  # Automatically add usage definition when none provided.
  if [ -z "$usage" ]; then
    log_trace "Adding default usage string"
    if [ "$main" = "1" ]; then
      if [ "$terminator" = "1" ]; then
        usage="$MG_CMDNAME [options] [--] arguments"
      else
        usage="$MG_CMDNAME [options] arguments"
      fi
    else
      if [ "$terminator" = "1" ]; then
        usage="[options] [--] arguments"
      else
        usage="[options] [--] arguments"
      fi
    fi
  fi

  # Automatically add verbosity control to main programs. We might want to also
  # automatically add --help support?
  if [ "$main" = "1" ]; then
    log_trace "Tweaking for main handling: verbosity and usage summary"
    if ! printf %s\\n "$options" | grep -q '^v[,[:space:]]'; then
      options="$(printf \
                    "%s\t%s\t%s\t%s\t%s" \
                      "v,verbose,verbosity" \
                      "OPTION,NOPREFIX" \
                      MG_VERBOSITY \
                      - \
                      "Set verbosity level, one of error, warn, notice, info, debug or trace")
$options"
    else
      options="$(printf \
                    "%s\t%s\t%s\t%s\t%s" \
                      "verbose,verbosity" \
                      "OPTION,NOPREFIX" \
                      MG_VERBOSITY \
                      - \
                      "Set verbosity level, one of error, warn, notice, info, debug or trace")
$options"
    fi

    #shellcheck disable=SC2034 # This is used by the usage function in log
    MG_USAGE=$(_help 0 2>&1)
  fi

  stack_let line=
  stack_let names=
  stack_let type=
  stack_let varname=
  stack_let default=
  stack_let text=
  stack_let found=
  stack_let candidate=
  stack_let opt=
  stack_let jump=

  # Set defaults, this will trigger function with the default value when such
  # exist.
  log_trace "Setting/triggering with defaults, when relevant"
  while IFS="$(printf '\n')" read -r line; do
    if [ -n "$line" ]; then
      _fields "$line"; # Sets: names, type, varname, default and text
      if [ "$default" != "$marker" ]; then
        _trigger \
            "$(printf %s\\n "$names" | cut -d , -f 1)" \
            "$default"
      fi
    fi
  done <<EOF
$(printf %s\\n "$options")
EOF

  while [ "$#" -gt "0" ]; do
    case "$1" in
      -[a-zA-Z0-9])
        found=
        jump=0
        while IFS="$(printf '\n')" read -r line && [ -z "$found" ]; do
          if [ -n "$line" ]; then
            _fields "$line"; # Sets: names, type, varname, default and text

            candidate=$(_find "${1#-}" "$names" 1 1)
            if [ -n "$candidate" ]; then
              if _has "FLAG" "$type"; then
                _trigger "$candidate" "1"
                found=$candidate
                jump=1
              elif _has 'OPT[A-Z]*' "$type"; then
                _trigger "$candidate" "$2"
                found=$candidate
                jump=2
              fi
            fi
          fi
        done <<EOF
$(printf %s\\n "$options")
EOF
        if [ -n "$found" ]; then
          parsed=$((parsed + jump))
          shift $jump
        else
          _critical "$1 is an unknown option"
          break
        fi
        ;;
      --)
        if [ "$terminator" = "1" ]; then
          parsed=$((parsed + 1)); shift
          break
        else
          _critical "$1 is an unknown option"
        fi
        ;;
      --*=*)
        stack_let val=
        found=
        jump=0
        opt="${1%=*}"; opt="${opt#--}"
        val="${1#*=}"
        while IFS="$(printf '\n')" read -r line && [ -z "$found" ]; do
          if [ -n "$line" ]; then
            _fields "$line"; # Sets: names, type, varname, default and text

            candidate=$(_find "$opt" "$names" 2)
            if [ -n "$candidate" ]; then
              if _has "FLAG" "$type"; then
                case "$(_tolower "$val")" in
                  true | on | yes | 1)
                    _trigger "$candidate" "1"
                    found=$candidate;;
                  false | off | no | 0)
                    _trigger "$candidate" "0"
                    found=$candidate;;
                  *)
                    _critical "Value in flag $1 not a recognised boolean!";;
                esac
                jump=1
              elif _has 'OPT[A-Z]*' "$type"; then
                _trigger "$candidate" "$val"
                found=$candidate
                jump=1
              fi
            fi
          fi
        done <<EOF
$(printf %s\\n "$options")
EOF
        stack_unlet val
        if [ -n "$found" ]; then
          parsed=$((parsed + jump))
          shift $jump
        else
          _critical "$opt is an unknown option"
          break
        fi
        ;;
      --*)
        found=
        jump=0
        while IFS="$(printf '\n')" read -r line && [ -z "$found" ]; do
          if [ -n "$line" ]; then
            _fields "$line"; # Sets: names, type, varname, default and text

            candidate=$(_find "${1#--}" "$names" 2)
            if [ -n "$candidate" ]; then
              if _has "FLAG" "$type"; then
                _trigger "$candidate" "1"
                found=$candidate
                jump=1
              elif _has 'OPT[A-Z]*' "$type"; then
                _trigger "$candidate" "$2"
                found=$candidate
                jump=2
              fi
            fi
          fi
        done <<EOF
$(printf %s\\n "$options")
EOF
        if [ -n "$found" ]; then
          parsed=$((parsed + jump))
          shift $jump
        else
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

  if [ -n "$reportvar" ]; then
    log_trace "Reporting # parsed args: $parsed into $reportvar"
    eval "$reportvar='$parsed'"
  fi
  stack_unlet line names type varname default text found candidate
  stack_unlet prefix options marker wrap synopsis description terminator \
              reportvar parsed usage
}