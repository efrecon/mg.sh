#shellcheck shell=sh

Describe 'options.sh'
  Include bootstrap.sh
  module options

  Describe 'parseopts'
    trigger() {
      printf %s=%s\\n "$1" "$2"
    }
    unquote() {
      sed -E 's/^([A-Z_]+)='\''?([^'\'']*)'\''?$/\1=\2/g'
    }
    runprefixed() {
      parseopts \
        --prefix "TEST" \
        "$@"
      # Only grep when there is something to grep, otherwise grep would
      # (wrongly) return an error
      if set | grep -q '^TEST_'; then
        # We manually unquote to smooth away differences between shells
        set | sort | grep '^TEST_' | unquote
      fi
    }
    unprefixed() {
      vname=$1
      shift
      parseopts \
        "$@"
      # Only grep when there is something to grep, otherwise grep would
      # (wrongly) return an error
      if set | grep -q "^${vname}="; then
        # We manually unquote to smooth away differences between shells
        set | sort | grep "^${vname}=" | unquote
      fi
    }

    shifter() {
      parseopts \
        --shift _begin \
        "$@"
      #shellcheck disable=SC2154 # This is set by parseopts
      echo "$_begin"
    }

    reporter() {
      parseopts \
        --vars _varlist \
        "$@"
      #shellcheck disable=SC2154 # This is set by parseopts
      echo "$_varlist"
    }

    It 'Set single-dash flag'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
        -- -f
      The line 1 should equal "TEST_THEFLAG=1"
    End
    It 'Defaults single-dash flag'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
        --
      The line 1 should equal "TEST_THEFLAG=0"
    End
    It 'Skips defaulting single-dash flag'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG THEFLAG - "set flag"
      The stdout should equal ""
    End
    It 'Set double-dashed flag'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
        -- --flag
      The line 1 should equal "TEST_THEFLAG=1"
    End
    It 'Set supports several double-dashed flag'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
        -- --theflag
      The line 1 should equal "TEST_THEFLAG=1"
    End
    It 'Set double-dashed flag explicitely (true)'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
        -- --flag=true
      The line 1 should equal "TEST_THEFLAG=1"
    End
    It 'Set double-dashed flag explicitely (false)'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
        -- --flag=false
      The line 1 should equal "TEST_THEFLAG=0"
    End
    It 'Set double-dashed flag explicitely (on)'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
        -- --flag=on
      The line 1 should equal "TEST_THEFLAG=1"
    End
    It 'Fails setting double-dashed flag explicitely with non-boolean value'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
        -- --flag=hello
      The line 1 should equal "TEST_THEFLAG=0"
      The error should include "boolean"
    End
    It 'Inverts single-dash flag'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG,INVERT THEFLAG 0 "set flag" \
        -- -f
      The line 1 should equal "TEST_THEFLAG=0"
    End
    It 'Inverts double-dashed flag'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG,INVERT THEFLAG 0 "set flag" \
        -- --flag
      The line 1 should equal "TEST_THEFLAG=0"
    End
    It 'Inverts double-dashed explicit flag'
      When call runprefixed \
        --options \
          f,flag,theflag FLAG,INVERT THEFLAG 0 "set flag" \
        -- --flag=true
      The line 1 should equal "TEST_THEFLAG=0"
    End

    It 'Set single-dash option'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
        -- -o hello
      The line 1 should equal "TEST_THEOPT=hello"
    End
    It 'Defaults single-dash option'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
        --
      The line 1 should equal "TEST_THEOPT=test"
    End
    It 'Skips defaulting single-dash option'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT - "set option" \
        --
      The stdout should equal ""
    End
    It 'Sets double-dashed option'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
        -- --option hello
      The line 1 should equal "TEST_THEOPT=hello"
    End
    It 'Sets several double-dashed options'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
        -- --theoption hello
      The line 1 should equal "TEST_THEOPT=hello"
    End
    It 'Overrides several double-dashed options'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
        -- \
          --option nonono \
          --theoption hello
      The line 1 should equal "TEST_THEOPT=hello"
    End
    It 'Sets double-dashed option (modern style with equal sign)'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
        -- --option=hello
      The line 1 should equal "TEST_THEOPT=hello"
    End
    It 'Sets empty double-dashed option (modern style with equal sign)'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
        -- --option=
      The line 1 should equal "TEST_THEOPT="
    End
    It 'Triggers with the name of the option'
      When call runprefixed \
        --options \
          o,option,theoption OPTION @trigger - "set option" \
        -- --option=hello
      The line 1 should equal "option=hello"
    End
    It 'Triggers with defaults'
      When call runprefixed \
        --options \
          o,option,theoption OPTION @trigger test "set option" \
        --
      The line 1 should equal "o=test"
    End

    It 'Set single-dash flag (unprefixed)'
      When call unprefixed \
        THEFLAG \
        --options \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
        -- -f
      The line 1 should equal "THEFLAG=1"
    End
    It 'Set single-dash option (unprefixed)'
      When call unprefixed \
        THEOPT \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
        -- -o hello
      The line 1 should equal "THEOPT=hello"
    End

    It 'Generates help'
      When call parseopts \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --help
      The stderr should include "Print this help"
      The status should be success
    End
    It 'Adds defaults to help'
      When call parseopts \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --help
      The stderr should include "default:"
      The status should be success
    End
    It 'Generates automatic usage in help'
      When call parseopts \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --help
      The stderr should include "USAGE"
      The status should be success
    End
    It 'Generates usage in help'
      When call parseopts \
        --usage "this is my marker" \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --help
      The stderr should include "this is my marker"
      The status should be success
    End
    It 'Generates synopsis in help'
      When call parseopts \
        --synopsis "this is my marker" \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --help
      The stderr should include "this is my marker"
      The status should be success
    End
    It 'Generates description in help'
      When call parseopts \
        --description "this is my marker" \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --help
      The stderr should include "this is my marker"
      The status should be success
    End

    It 'Generates argument shifting information'
      When call shifter \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- -f -- hello
      The line 1 should equal "2"
    End
    It 'Generates argument shifting information without double-dash separator'
      When call shifter \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- -f hello
      The line 1 should equal "1"
    End

    It 'Fails when given wrong option'
      When call parseopts \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --myoption toto
      The stderr should include "myoption is an unknown option"
    End
    It 'Fails when given wrong flag'
      When call parseopts \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --myflag
      The stderr should include "myflag is an unknown option"
    End

    It 'Sets flags and options (long)'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --flag --option hello
      The line 1 should equal "TEST_THEFLAG=1"
      The line 2 should equal "TEST_THEOPT=hello"
    End
    It 'Sets flags and options (short)'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- -f -o hello
      The line 1 should equal "TEST_THEFLAG=1"
      The line 2 should equal "TEST_THEOPT=hello"
    End
    It 'Sets flags and options (concatenated)'
      When call runprefixed \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- -fo hello
      The line 1 should equal "TEST_THEFLAG=1"
      The line 2 should equal "TEST_THEOPT=hello"
    End

    It 'Reports variables'
      When call reporter \
        --prefix TEST \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --flag --option hello
      The line 1 should equal "TEST_THEFLAG TEST_THEOPT"
    End
    It 'Does not report default variables'
      When call reporter \
        --prefix TEST \
        --options \
          o,option,theoption OPTION THEOPT test "set option" \
          f,flag,theflag FLAG THEFLAG 0 "set flag" \
          h,help FLAG @HELP - "Print this help" \
        -- --option hello
      The line 1 should equal "TEST_THEOPT"
    End
  End
End