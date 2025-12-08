# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2025-12-08

### Changed
- **Breaking:** `wth add` now takes `<existing-worktree-path> <new-worktree-name>` instead of just `<worktree-name>`
  - Can now be called from anywhere, consistent with `merge` and `clean` commands
  - Use `.` as the path when inside a worktree for the previous behavior

## [0.2.0] - 2025-12-08

### Added
- `wth add <worktree-name>` command to quickly create new feature worktrees
- `wth --version` and `wth -v` flags to display version number
- Version number displayed in help text
- CI workflow for automated testing
- Test suite for all commands

### Fixed
- Fixed worktree detection in `merge` command (was comparing commit hash instead of branch name)

## [0.1.0] - 2025-12-07

### Added
- `wth init <repo-url> [project-folder]` command to initialize a project with worktrees
- `wth merge [--push] <feature-worktree-path> [target-branch]` command to merge feature branches
- `wth clean <feature-worktree-path>` command to remove worktrees and delete branches
- Optional `--push` flag for merge command to push after merging
- Optional target branch parameter for merge command (defaults to main)
- Automatic project name derivation from repo URL
- Remote branch existence check before deletion
- GitHub release workflow with Homebrew formula updates
