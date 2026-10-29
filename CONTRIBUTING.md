# Contributing to GeauxPark

## Workflow

1. Pick an issue from the task board and assign it to yourself.
2. Update your local `main`, then make a branch from it named for the work: `feature/map-screen`, `fix/lot-hours`, `docs/readme`.
   ```bash
   git switch main
   git pull --ff-only origin main
   git switch -c feature/short-description
   ```
3. Commit small pieces often (a few times a week). Write messages that say what changed, like `Add lot details screen`.
4. Before you push, run:
   ```bash
   flutter analyze
   flutter test
   ```
5. Before opening or merging a pull request, rebase your branch onto the latest `main` and resolve any conflicts during the rebase:
   ```bash
   git fetch origin
   git rebase origin/main
   ```
   Run the checks again, then push the updated branch with `git push --force-with-lease`. Never merge `main` into a feature branch, and do not resolve conflicts by editing `main` directly.
6. Open a pull request into `main` and fill out the template. Put `Closes #<issue>` in the description.
7. One teammate reviews and approves, the branch must contain the latest `main`, and all automated checks must pass before merging.
8. Merge feature branches into `main` with **Squash and merge** so the direction of integration is always feature → `main` and the history stays easy to follow. Nobody pushes straight to `main`.

## Task board

Every piece of work is an issue with a description, a "done when" checklist, an assignee, and a milestone (MVP or Final). Move it across the board as you work and close it when the PR merges.

## Builds

GitHub Actions builds the app on every push and pull request (analyze, test, build APK). If the build is red, fixing it comes first.
