---
name: git-history-hygiene
description: Keep git history clean for each goal-oriented work unit. Use when Codex starts new implementation work, prepares a PR/review request, or needs to ensure unrelated commits/diffs are not mixed.
---

# Git History Hygiene

## Required Rules
- Treat one "work" as one goal-oriented work unit (usually one PR branch), not one commit.
- Before starting a new work unit, run `git status -sb` and `git log --oneline origin/main..HEAD`.
- If unrelated commits or diffs are present, create a new branch from the latest `main` and carry only required diffs (for example: cherry-pick).
- Multiple commits are allowed within the same work unit.
- Before creating a PR or requesting review, check again that unrelated diffs are not mixed.

## Start-Of-Work Checks
1. Run `git status -sb`.
2. Run `git log --oneline origin/main..HEAD`.
3. If the worktree is clean and no unrelated commits are listed, continue.
4. If unrelated changes exist, move work to a clean branch from `main`.

## Pre-PR Checks
1. Run `git status -sb`.
2. Confirm only intended files are changed.
3. Run `git log --oneline origin/main..HEAD`.
4. Confirm only intended commits are included.
