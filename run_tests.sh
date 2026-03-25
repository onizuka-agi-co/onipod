#!/bin/bash

# Test Runner for Podman Manager
# This script provides a convenient way to run the test suites

TEST_SUITE_BASIC="/workspace/test_podman_manager.sh"
TEST_SUITE_COMPREHENSIVE="/workspace/comprehensive_test_podman_manager.sh"

echo "Podman Manager Test Runner"
echo "=========================="

case "${1:-comprehensive}" in
    "basic")
        echo "Running basic test suite..."
        if [[ -f "$TEST_SUITE_BASIC" ]]; then
            chmod +x "$TEST_SUITE_BASIC"
            "$TEST_SUITE_BASIC"
        else
            echo "Error: Basic test suite not found at $TEST_SUITE_BASIC"
            exit 1
        fi
        ;;
    "comprehensive"|"full")
        echo "Running comprehensive test suite..."
        if [[ -f "$TEST_SUITE_COMPREHENSIVE" ]]; then
            chmod +x "$TEST_SUITE_COMPREHENSIVE"
            "$TEST_SUITE_COMPREHENSIVE"
        else
            echo "Error: Comprehensive test suite not found at $TEST_SUITE_COMPREHENSIVE"
            exit 1
        fi
        ;;
    "both")
        echo "Running both test suites..."
        if [[ -f "$TEST_SUITE_BASIC" ]]; then
            echo "Running basic test suite..."
            chmod +x "$TEST_SUITE_BASIC"
            "$TEST_SUITE_BASIC"
            echo ""
        else
            echo "Warning: Basic test suite not found at $TEST_SUITE_BASIC"
        fi

        if [[ -f "$TEST_SUITE_COMPREHENSIVE" ]]; then
            echo "Running comprehensive test suite..."
            chmod +x "$TEST_SUITE_COMPREHENSIVE"
            "$TEST_SUITE_COMPREHENSIVE"
        else
            echo "Error: Comprehensive test suite not found at $TEST_SUITE_COMPREHENSIVE"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 [basic|comprehensive|both]"
        echo "  basic         - Run the basic test suite"
        echo "  comprehensive - Run the comprehensive test suite (default)"
        echo "  both          - Run both test suites"
        exit 1
        ;;
esac