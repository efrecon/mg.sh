#shellcheck shell=sh

Describe 'controls.sh'
  Include bootstrap.sh
  module controls

  Describe 'backoff_loop'
    success() { echo "output" && return 0; }
    failure() { echo "output" && return 1; }

    It 'Run once on success'
      When call backoff_loop --sleep 1 -- success
      The output should eq "output"
      The status should be success
    End

    It 'Run once by default'
      When call backoff_loop -- success
      The output should eq "output"
      The status should be success
    End

    It 'Properly jump to command when no -- specified'
      When call backoff_loop --sleep 1 success
      The output should eq "output"
      The status should be success
    End

    It 'Run once on with timeout success'
      When call backoff_loop --sleep 1 --timeout 1 -- failure
      The output should eq "output"
      The status should be success
    End

    It 'Run twice on with timeout success'
      When call backoff_loop --sleep 1 --max 2 --timeout 3 -- failure
      The lines of stdout should equal 2
      The status should be success
    End

    It 'Run twice with complex --loop spec'
      When call backoff_loop --loop 1:2::3 -- failure
      The lines of stdout should equal 2
      The status should be success
    End

    It 'Can mix complex --loop spec and regular options'
      When call backoff_loop --loop 1:2 --timeout 3 -- failure
      The lines of stdout should equal 2
      The status should be success
    End

    It 'Fails with an unknown option'
      When call backoff_loop --unknown
      The status should be failure
      The error should include --unknown
    End

    It 'Fails when no wait time specified'
      When call backoff_loop --sleep ""
      The status should be failure
      The error should include waiting
    End

    It 'Fails when wait time is not an integer'
      When call backoff_loop --sleep "asd"
      The status should be failure
      The error should include integer
    End
    It 'Fails when wait time is too small'
      When call backoff_loop --sleep 0
      The status should be failure
      The error should include positive
    End

    It 'Fails when factor is not an integer'
      When call backoff_loop --factor "asd"
      The status should be failure
      The error should include integer
    End
    It 'Fails when factor is too small'
      When call backoff_loop --factor 0
      The status should be failure
      The error should include positive
    End

    It 'Fails when max is not an integer'
      When call backoff_loop --max "asd"
      The status should be failure
      The error should include integer
    End
    It 'Fails when max is too small'
      When call backoff_loop --max 0
      The status should be failure
      The error should include positive
    End

    It 'Fails when timeout is not an integer'
      When call backoff_loop --timeout "asd"
      The status should be failure
      The error should include integer
    End
    It 'Fails when timeout is too small'
      When call backoff_loop --timeout 0
      The status should be failure
      The error should include positive
    End
  End

  Describe "var_exists"
    unset TEST || true

    It "Detects that the variable TEST does not exists"
      When call var_exists TEST
      The status should be failure
    End

    # shellcheck disable=SC2034 # Variable is tested here under
    TEST=
    It "Detects that the variable TEST exists when empty"
      When call var_exists TEST
      The status should be success
    End

    # shellcheck disable=SC2034 # Variable is tested here under
    TEST="test"
    It "Detects that the variable TEST exists"
      When call var_exists TEST
      The status should be success
    End
  End

  Describe "var_empty"
    unset TEST || true

    It "Detects that the variable TEST is empty when it does not exists"
      When call var_empty TEST
      The status should be success
    End

    # shellcheck disable=SC2034 # Variable is tested here under
    TEST=
    It "Detects that the variable TEST is empty"
      When call var_empty TEST
      The status should be success
    End

    # shellcheck disable=SC2034 # Variable is tested here under
    TEST="test"
    It "Detects that the variable TEST is not empty"
      When call var_empty TEST
      The status should be failure
    End
  End
End