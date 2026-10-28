# Contributing to GeauxPark

## Workflow

1. Pick an issue from the task board and assign it to yourself.
2. Make a branch off `main` named for the work: `feature/map-screen`, `fix/lot-hours`, `docs/readme`.
3. Commit small pieces often (a few times a week). Write messages that say what changed, like `Add lot details screen`.
4. Before you push, run:
   ```bash
   flutter analyze
   flutter test
   ```
5. Open a pull request into `main` and fill out the template. Put `Closes #<issue>` in the description.
6. One teammate reviews and approves, and the automated build has to pass before merging.
7. Nobody pushes straight to `main`.

## Task board

Every piece of work is an issue with a description, a "done when" checklist, an assignee, and a milestone (MVP or Final). Move it across the board as you work and close it when the PR merges.

## Builds

GitHub Actions builds the app on every push and pull request (analyze, test, build APK). If the build is red, fixing it comes first.
