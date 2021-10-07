#shellcheck shell=sh

Describe 'text.sh'
  Include bootstrap.sh
  module text

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

  Describe 'unboolean'
    It "Understands false"
      When call unboolean false
      The output should eq "0"
    End
    It "Understands f"
      When call unboolean f
      The output should eq "0"
    End
    It "Understands off"
      When call unboolean off
      The output should eq "0"
    End
    It "Understands no"
      When call unboolean no
      The output should eq "0"
    End
    It "Understands n"
      When call unboolean n
      The output should eq "0"
    End
    It "Understands 0"
      When call unboolean 0
      The output should eq "0"
    End
    It "Understands true"
      When call unboolean true
      The output should eq "1"
    End
    It "Understands t"
      When call unboolean t
      The output should eq "1"
    End
    It "Understands on"
      When call unboolean on
      The output should eq "1"
    End
    It "Understands yes"
      When call unboolean yes
      The output should eq "1"
    End
    It "Understands y"
      When call unboolean y
      The output should eq "1"
    End
    It "Understands 1"
      When call unboolean 1
      The output should eq "1"
    End
    It "Understands any number"
      When call unboolean 234
      The output should eq "1"
    End
    It "Does not understand test"
      When call unboolean test
      The status should be failure
    End
    It "Is not case sensitive"
      When call unboolean FaLSe
      The output should eq "0"
    End
    It "Recognises several arguments"
      When call unboolean TrUE FaLSe
      The line 1 should eq "1"
      The line 2 should eq "0"
    End
  End

  Describe "is_true/false"
    It "Reports true"
      When call is_true "true"
      The status should be success
    End
    It "Reports false"
      When call is_false "false"
      The status should be success
    End
  End

  Describe "to_upper"
    It "Converts one argument to upper"
      When call to_upper "test"
      The output should eq "TEST"
    End
    It "Converts all arguments to upper"
      When call to_upper "test"   "test"
      The output should eq "TEST TEST"
    End
    It "Returns an empty string when called with empty argument"
      When call to_upper ""
      The output should eq ""
    End
  End

  Describe "to_lower"
    It "Converts one argument to lower"
      When call to_lower "TEST"
      The output should eq "test"
    End
    It "Converts all arguments to lower"
      When call to_lower "TEST"  "TEST"
      The output should eq "test test"
    End
    It "Returns an empty string when called with empty argument"
      When call to_upper ""
      The output should eq ""
    End
  End
End
