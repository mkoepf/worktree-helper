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
# Test: Init command clones repo and sets up worktrees
# ------------------------------------------------------------------------------
test_init_command() {
    local test_dir
    test_dir=$(mktemp -d)
    trap "rm -rf '$test_dir'" RETURN

    # Create a bare repo to clone from with 'main' as default branch
    cd "$test_dir"
    git init --bare --initial-branch=main origin.git --quiet

    # Create a temporary clone to add initial commit
    cd "$test_dir"
    git clone origin.git temp-clone --quiet
    cd temp-clone
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "test" > file.txt
    git add file.txt
    git commit -m "initial" --quiet
    git push --quiet

    # Now test wth init
    cd "$test_dir"
    rm -rf temp-clone
    "$WTH" init "$test_dir/origin.git" myproject

    # Check primary repo exists and is detached
    if [ -d "myproject" ]; then
        pass "wth init creates project directory"
    else
        fail "wth init should create project directory"
        return
    fi

    cd myproject
    local head_status
    head_status=$(git rev-parse --abbrev-ref HEAD)
    if [ "$head_status" = "HEAD" ]; then
        pass "wth init detaches primary worktree"
    else
        fail "wth init should detach primary worktree, got: $head_status"
    fi

    # Check main worktree exists
    cd "$test_dir"
    if [ -d "myproject-main" ]; then
        pass "wth init creates main worktree"
    else
        fail "wth init should create myproject-main directory"
        return
    fi

    cd myproject-main
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$branch" = "main" ]; then
        pass "wth init main worktree is on main branch"
    else
        fail "wth init main worktree should be on main branch, got: $branch"
    fi
}

# ------------------------------------------------------------------------------
# Test: Init command derives project name from URL
# ------------------------------------------------------------------------------
test_init_derives_name() {
    local test_dir
    test_dir=$(mktemp -d)
    trap "rm -rf '$test_dir'" RETURN

    # Create a bare repo with 'main' as default branch
    cd "$test_dir"
    git init --bare --initial-branch=main awesome-project.git --quiet

    # Add initial commit
    cd "$test_dir"
    git clone awesome-project.git temp-clone --quiet
    cd temp-clone
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "test" > file.txt
    git add file.txt
    git commit -m "initial" --quiet
    git push --quiet

    # Test init without project folder argument
    cd "$test_dir"
    rm -rf temp-clone
    "$WTH" init "$test_dir/awesome-project.git"

    if [ -d "awesome-project" ] && [ -d "awesome-project-main" ]; then
        pass "wth init derives project name from URL"
    else
        fail "wth init should derive project name 'awesome-project' from URL"
    fi
}

# ------------------------------------------------------------------------------
# Test: Clean command removes worktree and branch
# ------------------------------------------------------------------------------
test_clean_command() {
    local test_dir
    test_dir=$(mktemp -d)
    trap "rm -rf '$test_dir'" RETURN

    # Set up a repo with worktrees
    cd "$test_dir"
    mkdir main-repo
    cd main-repo
    git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "test" > file.txt
    git add file.txt
    git commit -m "initial" --quiet

    # Create feature worktree
    git worktree add ../feature-wt -b feature-branch --quiet

    # Verify setup
    if [ ! -d "../feature-wt" ]; then
        fail "Test setup failed: feature-wt not created"
        return
    fi

    # Run clean from outside the worktree
    cd "$test_dir"
    "$WTH" clean "$test_dir/feature-wt"

    # Check worktree is removed
    if [ ! -d "$test_dir/feature-wt" ]; then
        pass "wth clean removes worktree directory"
    else
        fail "wth clean should remove worktree directory"
    fi

    # Check branch is deleted
    cd "$test_dir/main-repo"
    if ! git branch --list | grep -q "feature-branch"; then
        pass "wth clean deletes local branch"
    else
        fail "wth clean should delete local branch"
    fi
}

# ------------------------------------------------------------------------------
# Test: Merge command merges feature into target
# ------------------------------------------------------------------------------
test_merge_command() {
    local test_dir
    test_dir=$(mktemp -d)
    trap "rm -rf '$test_dir'" RETURN

    # Create a bare repo (origin) with 'main' as default branch
    cd "$test_dir"
    git init --bare --initial-branch=main origin.git --quiet

    # Clone and set up initial state
    cd "$test_dir"
    git clone origin.git main-repo --quiet
    cd main-repo
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "initial" > file.txt
    git add file.txt
    git commit -m "initial" --quiet
    git push -u origin main --quiet

    # Detach primary and create main worktree
    git switch --detach --quiet
    git worktree add ../main-wt main --quiet

    # Create feature worktree with changes
    git worktree add ../feature-wt -b feature-branch --quiet
    cd ../feature-wt
    echo "feature change" > feature.txt
    git add feature.txt
    git commit -m "Add feature" --quiet

    # Run merge
    cd "$test_dir"
    "$WTH" merge "$test_dir/feature-wt"

    # Verify merge happened in main worktree
    cd "$test_dir/main-wt"
    if [ -f "feature.txt" ]; then
        pass "wth merge integrates feature changes into main"
    else
        fail "wth merge should integrate feature.txt into main worktree"
    fi

    # Verify main branch has the commit
    if git log --oneline | grep -q "Add feature"; then
        pass "wth merge commit appears in main branch history"
    else
        fail "wth merge should add feature commit to main branch"
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
test_init_command
test_init_derives_name
test_clean_command
test_merge_command

echo ""
echo "----------------------------------------"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
fi
