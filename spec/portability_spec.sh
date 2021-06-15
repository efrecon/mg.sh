#shellcheck shell=sh

Describe 'portability.sh'
  Include locals.sh
  Include portability.sh

  Describe 'base64'
    # Define a helper function to encapsulate the pipe
    encdec() { printf %s "$1" | "b64_$2"; }

    It "Encodes the string test"
      When call encdec test encode
      The output should eq "dGVzdA=="
    End

    It "Decodes to the string test"
      When call encdec "dGVzdA==" decode
      The output should eq "test"
    End
  End

  Describe 'envsubst'
    # shellcheck disable=SC2034 # We use TEST in the templates
    test_subst() { TEST=${2:-test} && printf %s\\n "$1" | mg_envsubst; }

    It "Replaces the TEST variable once"
      When call test_subst "this is a \$TEST"
      The output should eq "this is a test"
    End

    It "Replaces the TEST variable twice"
      When call test_subst "this is a \$TEST \$TEST"
      The output should eq "this is a test test"
    End

    It "Recognises the \$\{\} form"
      When call test_subst "this is a \${TEST}"
      The output should eq "this is a test"
    End

    It "Does not replace a variable that does not exist"
      When call test_subst "this is a \$NOTTEST"
      The output should eq "this is a "
    End
  End
End