#!/usr/bin/env sh

parseopts() {
  stack_let prefix
  stack_let options

   # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -p | --prefix)
        prefix=$2; shift 2;;

      -o | --options | --opts)
        shift;
        while [ "${1#-}" = "$1" ]; do
          # Check params and scream?
          options="$options$(printf "%s\t%s\t%s\t%s\t%s\t" "$1" "$2" "$3" "$4" "$5")"
          shift 5;
        done
        ;;

      --)
        shift; break;;

      *)
        break;;
    esac
  done

  while [ $# -gt 0 ]; do
    case "$1" in
      -[a-zA-Z0-9])
        while IFS="$(printf '\t')" read -r names type varname default text; do
          if [ -n "$prefix" ]; then
            varname="${prefix%_}_${varname#_}"
          fi

          OIFS=$IFS; found=""
          IFS=,; for nm in $(printf %s\\n "$names"); do
            if [ "${1#-}" = "${nm#-}" ]; then
              case "$(printf %s\\n "$type" | tr '[:lower:]' '[:upper:]')" in
                FLAG)
                  eval "$(printf "%s=1" "$varname")"
                  found=flag
                  shift
                  break;;
                OPT*)
                  eval "$(printf "%s=%s" "$varname" "$2")"
                  found=option
                  shift 2
                  break;;
              esac
            fi
          done
          IFS=$OIFS
          if [ -z "$found" ]; then
            log_error "$1 unknown option"
          else
            log_trace "Found $found"
          fi
        done <<EOF
$(printf %s\\n "$options")
EOF
        ;;
      --*=*)
        while IFS="$(printf '\t')" read -r names type varname default text; do
          if [ -n "$prefix" ]; then
            varname="${prefix%_}_${varname#_}"
          fi

          opt="${1%=*}"; opt="${1#--}"
          val="${1#*=}"
          OIFS=$IFS; found=""
          IFS=,; for nm in $(printf %s\\n "$names"); do
            if [ "$opt" = "${nm#-}" ]; then
              case "$(printf %s\\n "$type" | tr '[:lower:]' '[:upper:]')" in
                FLAG)
                  case "$(printf %s\\n "$val" | tr '[:upper:]' '[:lower:]')" in
                    true | on | yes | 1)
                      eval "$(printf "%s=1" "$varname")"
                      found=flag
                      shift
                      break;;
                    false | off | no | 0)
                      eval "$(printf "%s=0" "$varname")"
                      found=flag
                      shift
                      break;;
                    *)
                      log_error "Value in flag $1 not a recognised boolean!"
                      shift;
                      break;;
                  esac
                  ;;
                OPT*)
                  eval "$(printf "%s=%s" "$varname" "$val")"
                  found=option
                  shift 2
                  break;;
              esac
            fi
          done
          IFS=$OIFS
          if [ -z "$found" ]; then
            log_error "$1 unknown option"
          else
            log_trace "Found $found"
          fi
        done <<EOF
$(printf %s\\n "$options")
EOF
        ;;
      *)
        break;;
    esac
  done
}