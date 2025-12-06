# wth — Worktree Helper

A lightweight utility that automates a clean, professional Git workflow using **git worktrees**.
Designed for multi-branch, multi-session development — especially when working with tools like Claude Code, where each worktree benefits from its own isolated directory, settings, and context.

This toolkit supports:

- Safe initialization of a project using worktrees
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

### 1. init — Initialize repository + main worktree

```
wth init <repo-url> <project-folder>
```

This clones the repo, detaches the primary worktree, and creates:

```
project/           (primary, parked)
project-main/      (main worktree)
```

Use the `*-main/` directory for development on the main branch.

---

### 2. merge — Merge a feature worktree into main

```
wth merge <feature-worktree-path>
```

This command:

1. Detects the feature branch from the worktree
2. Fetches from origin
3. Rebases the feature branch onto `origin/main`
4. Locates the main worktree automatically
5. Pulls latest main from origin
6. Fast-forward merges the feature branch
7. Pushes to `origin/main`

If rebase conflicts occur, the rebase is aborted and the script exits.

Example:

```
wth merge ../project-feature-login
```

---

### 3. clean — Remove worktree + delete branch (local + remote)

```
wth clean <feature-worktree-path>
```

This:

- Removes the worktree
- Deletes the local branch (tries `-d` first, falls back to `-D`)
- Deletes the remote branch (if it exists)
- Prunes stale remote refs

Example:

```
wth clean ../project-feature-login
```

---

## Complete Workflow Example

Start project:

```
wth init https://github.com/acme/awesome.git awesome
cd awesome-main
```

Create feature worktree:

```
git worktree add ../awesome-login -b feature-login main
cd ../awesome-login
# ... make changes ...
git commit -am "Add login feature"
```

Merge back into main:

```
wth merge ../awesome-login
```

Cleanup:

```
wth clean ../awesome-login
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
