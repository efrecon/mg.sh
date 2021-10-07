#!/bin/sh

# Declare MG_LIBPATH
if [ -n "${BASH:-}" ]; then
  # shellcheck disable=SC3028,SC3054 # We know BASH_SOURCE only exists under bash!
  MG_LIBPATH=${MG_LIBPATH:-$(dirname "${BASH_SOURCE[0]}")}
elif command -v "lsof" >/dev/null 2>&1; then
  # Introspect by asking which file descriptors the current process has opened.
  # This is an evolution of https://unix.stackexchange.com/a/351658 and works as
  # follows:
  # 1. lsof is called to list out open files. lsof will have different
  #    results/outputs depending on the shell used. For example, when using
  #    busybox, there are few built-ins.
  # 2. Remove the \0 to be able to understand the result as text
  # 3. Transform somewhat the output of lsof on "normal" distros/shell to
  #    something that partly resembles lsof on busybox, i.e. file descritor id,
  #    followed by space, followed by file spec.
  # 4. Remove irrelevant stuff, these have a tendency to happen after the file
  #    that we are looking for. This is because the pipe implementing this is
  #    active, so binaries, devices, etc. will be opened when it runs in order
  #    to implement it. So we remove /dev references, pipe: (busybox), and all
  #    references to the binaries used when implementing the pipe itself.
  # 5. The file we are looking for is the last whitespace separated field of the
  #    last line.
  MG_LIBPATH=${MG_LIBPATH:-$(dirname "$(lsof -p "$$" -Fn0 2>/dev/null |
                                        tr -d '\0' |
                                        sed -E 's/^f([0-9]+)n(.*)/\1 \2/g' |
                                        grep -vE -e '\s+(/dev|pipe:|socket:)' -e '[a-z/]*/bin/(tr|grep|lsof|tail|sed|awk)' |
                                        tail -n 1 |
                                        awk '{print $NF}')")}
else
  # Introspect by checking which file descriptors the current process has
  # opened as of under the /proc tree.
  # 1. List opened file descriptors for the current process, sorted by last
  #    access time. Listing is in long format to be able to catch the trailing
  #    -> that will point to the real location of the file.
  # 2. Isolate the symlinking part of the ls -L listing.
  # 3. Remove irrelevant stuff, these have a tendency to happen after the file
  #    that we are looking for. This is because the pipe implementing this is
  #    active, so binaries, devices, etc. will be opened when it runs in order
  #    to implement it. So we remove /dev references, pipe: (busybox), and all
  #    references to the binaries used when implementing the pipe itself.
  # 4. The file we are looking for is the last whitespace separated field of
  #    the last line.
  # 5. Finally, use sed to remove the /bootstrap.sh (likely) from the end of
  #    the name. We do not use dirname on purpose as this would introduce yet
  #    another process to filter out and reason about.

  # shellcheck disable=SC2010 # We believe this is ok in the context of /proc
  MG_LIBPATH=${MG_LIBPATH:-$(ls -tul "/proc/$$/fd" 2>/dev/null |
                                        grep -oE '[0-9]+\s+->\s+.*' |
                                        grep -vE -e '\s+(/dev|pipe:|socket:)' -e '[a-z/]*/bin/(ls|grep|tail|sed|awk)'|
                                        tail -n 1 |
                                        awk '{print $NF}' |
                                        sed -E 's~/[^/]+$~~')}
fi

# Protect against double loading
if printf %s\\n "${MG_MODULES:-}"|grep -q "bootstrap"; then
  return
else
  MG_MODULES="${MG_MODULES:-} bootstrap"
fi

path_split() {
  printf %s\\n "$1" | awk '{split($1,DIRS,/:/); for ( D in DIRS ) {printf "%s\n", DIRS[D];} }'
}

path_search() {
  # shellcheck disable=SC3043 # local exists in most shell implementations anyhow
  local _d || true
  for _d in $(path_split "$1"); do
    if [ -f "${_d}/${2}" ]; then
      printf %s/%s\\n "$_d" "$2"
      unset _d
      return
    fi
  done
}

bootstrap() {
  MG_LIBPATH="$1"
}

has_module() {
  # shellcheck disable=SC3043 # local exists in most shell implementations anyhow
  local _module || true

  for _module; do
    if printf %s\\n "${MG_MODULES:-}"|grep -q "$_module"; then
      unset _module
      return 0
    fi
  done
  unset _module
  return 1
}

module() {
  if [ -z "${MG_LIBPATH:-}" ]; then
    echo "Provide MG_LIBPATH, a colon-separated search path for scripts, possibly via bootstrap function" >& 2
    exit
  else
    # shellcheck disable=SC3043 # local exists in most shell implementations anyhow
    local _module _d || true

    for _module; do
      for _d in $(path_split "$MG_LIBPATH"); do
        if has_module "$_module"; then
          unset _module; # Use the variable as a marker for module found.
          break
        elif [ -f "${_d}/${_module}.sh" ]; then
          # Log if we can
          if type log_debug | head -n 1 | grep -q function; then
            log_debug "Sourcing ${_d}/${_module}.sh"
          fi
          # shellcheck disable=SC1090
          . "${_d}/${_module}.sh"

          # Add module to list of known modules
          if ! printf %s\\n "${MG_MODULES:-}"|grep -q "$_module"; then
            MG_MODULES="${MG_MODULES:-} $_module"
          fi

          unset _module; # Use the variable as a marker for module found.
          break
        fi
      done
      if [ -n "${_module:-}" ]; then
        echo "Cannot find module $_module in $MG_LIBPATH !" >& 2
        exit 1
      fi
    done
    unset _d
  fi
}
