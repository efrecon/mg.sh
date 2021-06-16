#shellcheck shell=sh

Describe 'interaction.sh'
  Include locals.sh
  Include log.sh
  Include options.sh
  Include controls.sh
  Include filesystem.sh
  Include portability.sh
  Include interaction.sh

  Describe 'prompt'
    askvar() {
      _value=$1
      shift
      prompt --varname QUESTION "$@" -- "This is a question" >/dev/null <<EOF
$(printf %s\\n "$_value")
EOF
      printf %s\\n "$QUESTION"
    }
    asknovar() {
      prompt "This is a question" <<EOF
$(printf %s\\n "$1")
EOF
    }

    unset QUESTION || true
    It "Sets the variable when it does not exist"
      When call askvar "test"
      The output should eq "test"
    End

    QUESTION=
    It "Sets the variable when it is empty"
      When call askvar "test"
      The output should eq "test"
    End

    QUESTION="do not touch"
    It "Does not set the variable when it exists"
      When call askvar "test"
      The output should eq "do not touch"
    End

    QUESTION="do not touch"
    It "Sets the variable when forced to"
      When call askvar "test" -f
      The output should eq "test"
    End

    It "Returns the value and the prompt without variable"
      When call asknovar "test"
      The output should eq "This is a question test"
    End
  End
End