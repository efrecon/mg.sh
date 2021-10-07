#shellcheck shell=sh

Describe 'bootstrap.sh'
  Include bootstrap.sh

  Describe 'Environment Discovery'
    It "Discovers mg.sh directory"
      When call module
      The variable MG_LIBPATH should equal "$( cd -P -- "$(dirname "$SHELLSPEC_SPECFILE")/.." && pwd -P )"
    End
  End

  Describe 'has_module'
    It 'Presence of bootstrap module'
      When call has_module bootstrap
      The status should be success
    End

    It 'Absence of log module'
      When call has_module log
      The status should be failure
    End
  End

  Describe 'module'
    It 'Loads text module'
      When call module text
      The status should be success
      The variable MG_MODULES should include "text"
      The variable MG_MODULES should include "bootstrap"
    End

    It 'Loads text module twice'
      When call module text
      The status should be success
      The variable MG_MODULES should include "text"
      The variable MG_MODULES should include "bootstrap"
    End
  End

  Describe 'path_split'
    It 'Splits properly'
      When call path_split "${MG_LIBPATH}:$(dirname "$SHELLSPEC_SPECFILE")"
      The status should be success
      The output should start with "${MG_LIBPATH}"
      The output should end with "$(dirname "$SHELLSPEC_SPECFILE")"
    End
  End

  Describe 'path_search'
    It 'Finds the location of log.sh'
      When call path_search "${MG_LIBPATH}:$(dirname "$SHELLSPEC_SPECFILE")" log.sh
      The status should be success
      The output should equal "${MG_LIBPATH%/}/log.sh"
    End
    It 'Fails finding an unknown file'
      When call path_search "${MG_LIBPATH}:$(dirname "$SHELLSPEC_SPECFILE")" _unKNOwn___.sh
      The status should be success
      The output should equal ""
    End
  End
End