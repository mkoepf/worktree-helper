# wth — Worktree Helper

A lightweight utility that automates a clean, professional Git workflow using **git worktrees**.
Designed for multi-branch, multi-session development — especially when working with tools like Claude Code, where each worktree benefits from its own isolated directory, settings, and context.

This toolkit supports:

- Safe initialization of a project using worktrees
- Quick creation of new feature worktrees
- Feature-branch development in isolated worktrees
- Fast-forward merges into remote main, automatically rebasing first
- Cleanup of worktrees and branches (local + remote)
- Zero confusion between primary clone, main worktree, and feature worktrees

---

## Why Worktrees?

Git worktrees let you have **multiple working directories** for the same repository, each tied to a different branch.

Advantages over multiple clones:

- No duplicate `.git` directories → minimal disk usage
- No drift (all branches share the same object database)
- Perfect isolation per feature
- Ideal for LLM-assisted workflows with project-local settings

---

## Installation

Save the script somewhere in your PATH (e.g. `~/bin/wth`) and make it executable:

```
chmod +x ~/bin/wth
```

---

## Commands

### `wth --version`

Display the version number.

---

### 1. init — Initialize repository + main worktree

```
wth init <repo-url> [project-folder]
```

If `project-folder` is omitted, it defaults to the repository name extracted from the URL.

**Equivalent git commands:**

```bash
git clone <repo-url> <project-folder>
cd <project-folder>
git switch --detach
git worktree add ../<project-folder>-main main
```

**Result:**

```
project/           (primary, parked in detached HEAD)
project-main/      (main worktree for development)
```

---

### 2. add — Create a new feature worktree

```
wth add <existing-worktree-path> <new-worktree-name>
```

Creates a new worktree with a new branch of the same name. Can be run from anywhere. The new worktree is created as a sibling to the specified existing worktree.

**Equivalent git commands:**

```bash
cd <existing-worktree-path>
git worktree add ../<new-worktree-name> -b <new-worktree-name>
```

**Example:**

```bash
wth add awesome-main feature-login
cd feature-login/
```

Or using `.` when inside a worktree:

```bash
cd awesome-main/
wth add . feature-login
cd ../feature-login/
```

**Result:**

```
awesome/              (primary, parked in detached HEAD)
awesome-main/         (main worktree)
feature-login/        (new feature worktree)
```

---

### 3. merge — Merge a feature worktree into a target branch

```
wth merge [--push] <feature-worktree-path> [target-branch]
```

- `target-branch` defaults to `main`
- Use `--push` to push to origin after merging

**Equivalent git commands:**

```bash
cd <feature-worktree-path>
git fetch origin
git rebase origin/<target-branch>     # aborts and exits on conflict
cd <target-worktree>                  # auto-detected via git worktree list
git pull origin <target-branch>
git merge --ff-only <feature-branch>
git push origin <target-branch>       # only with --push
```

If rebase conflicts occur, the rebase is aborted and the script exits.

---

### 4. clean — Remove worktree + delete branch (local + remote)

```
wth clean <feature-worktree-path>
```

**Equivalent git commands:**

```bash
cd <feature-worktree-path>
branch=$(git rev-parse --abbrev-ref HEAD)
cd <original-directory>
git worktree remove <feature-worktree-path>
git branch -d <branch>                # falls back to -D if needed
git push origin --delete <branch>     # skipped if branch doesn't exist on remote
git fetch --prune
```

---

## Complete Workflow Example

Start project:

```
wth init https://github.com/acme/awesome.git
cd awesome-main
```

Create feature worktree:

```
wth add . feature-login
cd ../feature-login
# ... make changes ...
git commit -am "Add login feature"
```

Merge back into main:

```
wth merge ../feature-login
```

Or merge and push in one step:

```
wth merge --push ../feature-login
```

Cleanup:

```
wth clean ../feature-login
```

---

## Recommended Layout

```
awesome/                ← primary repo (never edited)
awesome-main/           ← main branch worktree
awesome-feature-x/      ← worktree for feature x
awesome-feature-y/      ← worktree for feature y
```

---

## Notes

- 1 worktree = 1 branch = 1 dev environment
- Never work inside the primary clone
- Always rebase before merging (the `merge` command does this automatically)
- Use `clean` after merging a feature branch

---

## Troubleshooting

### "main is already checked out in …"
Detach the primary worktree:

```
cd project/
git switch --detach
```

### Rebase conflicts during merge
The script aborts the rebase automatically. Fix conflicts manually:

```
cd <feature-worktree>
git rebase origin/main
# resolve conflicts
git rebase --continue
```

Then rerun `wth merge`.

---

## License

MIT  
