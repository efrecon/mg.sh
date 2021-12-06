#shellcheck shell=sh

Describe 'locals.sh'
  Include bootstrap.sh

  # shellcheck disable=2034 # Internal variable, used mostly for testing
  __MG_LOCALS_FORCE=1; # Force using our implementation to test it
  module locals

  Describe 'Internal let/unlet'
    first() {
      stack_let a=first
      echo "$a"
      stack_unlet a
    }
    second() {
      stack_let a=second
      first
      echo "$a"
      stack_unlet a
    }
    global_first() {
      a=global
      first
      echo "$a"
    }
    global_second() {
      a=global
      second
      echo "$a"
    }
    double() {
      stack_let a=a b=b
      echo "$a"
      echo "$b"
      stack_unlet a b
    }
    empty() {
      stack_let a=a b
      echo "$a"
      echo "${b:-"<unset>"}"
      stack_unlet a b
    }

    It 'Pushes one state'
      When call global_first
      The line 1 should equal first
      The line 2 should equal global
    End

    It 'Pushes two states'
      When call global_second
      The line 1 should equal first
      The line 2 should equal second
      The line 3 should equal global
    End

    It 'Can set several vars at once'
      When call double
      The line 1 should equal a
      The line 2 should equal b
    End

    It 'Can set empty variables'
      When call empty
      The line 1 should equal a
      The line 2 should equal "<unset>"
    End
  End
End