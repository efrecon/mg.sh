#shellcheck shell=sh

Describe 'pack.sh'
  # Touch the file pass as a parameter and pack the library to it. Pass any
  # further options to the pack.sh script.
  overwrite() {
    _file=$1; shift
    touch "$_file"
    "${SHELLSPEC_PROJECT_ROOT}/bin/pack.sh" -o "$_file" "$@"
  }
  # Pack the entire library in a wrapper that is able to callout any function of
  # the library. Once done, use the wrapper to call the function.  The function
  # and its arguments are the arguments to this function.
  callout() {
    _file="${SHELLSPEC_WORKDIR}/pack.${SHELLSPEC_UNIXTIME}.$$.sh"
    "${SHELLSPEC_PROJECT_ROOT}/spec/support/maker.sh" -w -- "$_file"
    "$_file" "$@"
  }

  It 'Creates a file'
    Path output="${SHELLSPEC_WORKDIR}/pack.$$.sh"
    When run "${SHELLSPEC_PROJECT_ROOT}/bin/pack.sh" -o "${SHELLSPEC_WORKDIR}/pack.$$.sh"
    The path output should be file
  End

  It 'Does not overwrite an existing file'
    Path output="${SHELLSPEC_WORKDIR}/empty.$$.sh"
    When call overwrite "${SHELLSPEC_WORKDIR}/empty.$$.sh"
    The status should be failure
    The path output should be empty file
    The stderr should include "${SHELLSPEC_WORKDIR}/empty.$$.sh"
  End

  It 'Can overwrite an existing file'
    Path output="${SHELLSPEC_WORKDIR}/empty.$$.sh"
    When call overwrite "${SHELLSPEC_WORKDIR}/empty.$$.sh" -w
    The status should be success
    The path output should be file
    The contents of file output should include mg.sh
  End

  It 'Output to stdout'
    When run "${SHELLSPEC_PROJECT_ROOT}/bin/pack.sh"
    The stdout should include mg.sh
  End

  It 'Can select modules'
    When run "${SHELLSPEC_PROJECT_ROOT}/bin/pack.sh" -- bootstrap
    The stdout should include "bootstrap.sh"
    The stdout should not include "log.sh"
  End

  It 'Can select modules recursively'
    When run "${SHELLSPEC_PROJECT_ROOT}/bin/pack.sh" -- options
    The stdout should include "bootstrap.sh"
    The stdout should include "log.sh"
    The stdout should include "options.sh"
  End

  It 'Can be packed and used'
    When call callout log_warn __test__
    The stderr should include __test__
    The status should be success
  End
End