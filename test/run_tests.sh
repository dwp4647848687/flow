#!/bin/bash
source "$(dirname "$0")/utils.sh"

test_list=(
    test_feature_creation_with_current_branch_main
)

# Run all tests
run_tests()
{
    for test in "${test_list[@]}"; do
        setup_test_env
        $test
        teardown_test_env
    done
}

run_tests
