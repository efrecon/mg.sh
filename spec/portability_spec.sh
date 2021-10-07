#shellcheck shell=sh

Describe 'portability.sh'
  Include bootstrap.sh
  module portability

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

  Describe 'read_f'
    readnprint() {
      read_s -r _varname <<EOF
$(printf %s\\n "$1")
EOF
      # shellcheck disable=SC2154 # set by read above
      printf %s\\n "$_varname"
    }

    It "Reads from stdin"
      When call readnprint "test"
      The output should eq "test"
    End
  End

  Describe 'readlink_f'
    # Create a temporary directory and symbolic links of various sorts inside
    # the directory.
    tmpdir=$(mktemp -d)
    ln -s "${tmpdir}/thefile" "${tmpdir}/theabslink"
    ln -s "${tmpdir}" "${tmpdir}/theabsdir"
    ( cd "$tmpdir" || return
      touch "thefile"
      ln -s "thefile" "thelink"
      ln -s "." "thedirlink"
    )

    It "Resolves existing files"
      When call readlink_f "${tmpdir}/thefile"
      The output should eq "${tmpdir}/thefile"
    End
    It "Resolves existing file links"
      When call readlink_f "${tmpdir}/thelink"
      The output should eq "${tmpdir}/thefile"
    End
    It "Resolves existing file absolute links"
      When call readlink_f "${tmpdir}/theabslink"
      The output should eq "${tmpdir}/thefile"
    End
    It "Resolves existing dir links"
      When call readlink_f "${tmpdir}/thedirlink"
      The output should eq "${tmpdir}"
    End
    It "Resolves existing dir abs links"
      When call readlink_f "${tmpdir}/theabsdir"
      The output should eq "${tmpdir}"
    End
    It "Resolves recursively links"
      When call readlink_f "${tmpdir}/thedirlink/thelink"
      The output should eq "${tmpdir}/thefile"
    End
    It "Resolves recursively abs links"
      When call readlink_f "${tmpdir}/theabsdir/theabslink"
      The output should eq "${tmpdir}/thefile"
    End

    rm -rf "$tmpdir"
  End
End