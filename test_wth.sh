#!/usr/bin/env bash
set -euo pipefail

# Test script for wth

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WTH="$SCRIPT_DIR/wth"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    echo -e "${GREEN}PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# ------------------------------------------------------------------------------
# Test: Version flag shows version
# ------------------------------------------------------------------------------
test_version_flag() {
    local output
    output=$("$WTH" --version 2>&1) || true
    if echo "$output" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        pass "wth --version shows version number"
    else
        fail "wth --version should show version number, got: $output"
    fi
}

# ------------------------------------------------------------------------------
# Test: Help text includes version
# ------------------------------------------------------------------------------
test_help_includes_version() {
    local output
    output=$("$WTH" 2>&1 || true)
    if echo "$output" | grep -qE 'wth [0-9]+\.[0-9]+\.[0-9]+'; then
        pass "Help text includes version"
    else
        fail "Help text should include version, got: $output"
    fi
}

# ------------------------------------------------------------------------------
# Test: Add command exists in help
# ------------------------------------------------------------------------------
test_add_in_help() {
    local output
    output=$("$WTH" 2>&1 || true)
    if echo "$output" | grep -q "wth add"; then
        pass "Help text includes add command"
    else
        fail "Help text should include add command, got: $output"
    fi
}

# ------------------------------------------------------------------------------
# Test: Add command creates worktree and branch
# ------------------------------------------------------------------------------
test_add_command() {
    local test_dir
    test_dir=$(mktemp -d)
    trap "rm -rf '$test_dir'" RETURN

    # Create a test repo structure similar to wth init
    cd "$test_dir"
    mkdir main-repo
    cd main-repo
    git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "test" > file.txt
    git add file.txt
    git commit -m "initial" --quiet

    # Create a worktree to simulate working from (like main worktree)
    git worktree add ../main-wt main --quiet 2>/dev/null || git worktree add ../main-wt --quiet

    # Run wth add from the main worktree
    cd ../main-wt
    "$WTH" add feature-test

    # Check that the worktree was created
    if [ -d "../feature-test" ]; then
        pass "wth add creates worktree directory"
    else
        fail "wth add should create worktree directory at ../feature-test"
        return
    fi

    # Check that the branch was created
    cd ../feature-test
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$branch" = "feature-test" ]; then
        pass "wth add creates branch with same name"
    else
        fail "wth add should create branch 'feature-test', got: $branch"
    fi
}

# ------------------------------------------------------------------------------
# Run tests
# ------------------------------------------------------------------------------
echo "Running wth tests..."
echo ""

test_version_flag
test_help_includes_version
test_add_in_help
test_add_command

echo ""
echo "----------------------------------------"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
fi
