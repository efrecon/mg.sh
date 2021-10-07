#shellcheck shell=sh

Describe 'log.sh'
    Include bootstrap.sh
    module log

    It 'Prints default usage'
        When run usage
        The error should include erroneous
        The status should be failure
    End

    It 'Prints defined usage'
        MG_USAGE="test"
        When run usage
        The error should include test
        The status should be failure
    End

    It 'Logs at info (by default)'
        When call log_info test
        The error should end with test
    End
    It 'Logs at warning (by default)'
        When call log_warn test
        The error should end with test
    End
    It 'Does not log at debug (by default)'
        When call log_debug test
        The error should equal ""
    End

    It 'Does not log at info (when at warn)'
        MG_VERBOSITY="warn"
        When call log_info test
        The error should equal ""
    End
    It 'Logs at warning (when at warn)'
        MG_VERBOSITY="warn"
        When call log_warn test
        The error should end with test
    End

    It 'Dies with a message'
        When run die test
        The error should end with test
        The status should be failure
    End
End