#shellcheck shell=sh

Describe 'text.sh'
  Include locals.sh
  Include log.sh
  Include options.sh
  Include text.sh

  Describe 'rndstr'
    It "Generates a string of 8 chars"
      When call rndstr
      The length of stdout should eq 8
    End

    It "Generates a string of 24 chars"
      When call rndstr --length 24
      The length of stdout should eq 24
    End

    It "Generates an empty string when called with 0"
      When call rndstr --length 0
      The output should eq ""
    End

    It "Generate a string containing a-z0-9A-Z,._+:@%- characters only"
      When call rndstr
      The output should match pattern '[a-z0-9A-Z,._+:@%-][a-z0-9A-Z,._+:@%-][a-z0-9A-Z,._+:@%-][a-z0-9A-Z,._+:@%-][a-z0-9A-Z,._+:@%-][a-z0-9A-Z,._+:@%-][a-z0-9A-Z,._+:@%-][a-z0-9A-Z,._+:@%-]'
    End

    It "Can restrict the output to other sets"
      When call rndstr --charset 'a-z'
      The output should match pattern '[a-z][a-z][a-z][a-z][a-z][a-z][a-z][a-z]'
    End

    It "Can restrict the output to a single char (this is... silly!)"
      When call rndstr --charset "a"
      The output should eq "aaaaaaaa"
    End
  End
End
