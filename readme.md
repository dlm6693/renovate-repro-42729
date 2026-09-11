# Minimal reproduction: postUpgradeTasks commits stale content

Reproduction for [renovatebot/renovate discussion #42729](https://github.com/renovatebot/renovate/discussions/42729)
(originally issue [#42710](https://github.com/renovatebot/renovate/issues/42710)).

Fix proposed in [renovatebot/renovate#45891](https://github.com/renovatebot/renovate/pull/45891).

## Current behavior

Renovate runs the `postUpgradeTasks` command, logs `Post-upgrade file saved` for
both `go.sum` files, and then commits **`app/go.sum` without the marker the
script wrote**. `lib/go.sum` gets the marker as expected.

## Expected behavior

Both `lib/go.sum` and `app/go.sum` contain the `// renovate-post-upgrade-marker`
line on the branch Renovate pushes, because `post-upgrade.sh` wrote the marker to
both files and Renovate read both back off disk.

## Why the two files behave differently

`postUpgradeCommandsExecutor` uses `.find()` to locate the `updatedArtifacts`
entry for a changed path, so only the **first** entry for that path receives the
post-upgrade content. `prepareCommit()` writes every entry to disk in array
order, so when a path has more than one entry a later stale duplicate overwrites
the one that was updated.

This repo is shaped to give exactly one path a duplicate entry and one path a
single entry, so the difference is visible in a single branch:

- `postUpdateOptions: ["gomodTidyAll"]` makes `lib`'s `updateArtifacts()` call
  also return its dependent's files (`app/go.mod`, `app/go.sum`) via
  `dependentFiles`.
- `app` also depends on `github.com/google/uuid` directly, so `app`'s own
  `updateArtifacts()` call returns `app/go.sum` too.

Result: `app/go.sum` has two entries and loses the marker. `lib/go.sum` has one
entry and keeps it.

## Layout

```
go.work           workspace over both modules
lib/              depends on github.com/google/uuid v1.3.0
app/              depends on lib (via replace) and uuid v1.3.0
post-upgrade.sh   appends a marker line to lib/go.sum and app/go.sum
renovate.json5    gomodTidyAll + postUpgradeTasks
```

`github.com/google/uuid` is pinned to `v1.3.0` so there is always a pending
update, and it has no transitive dependencies.

## How to run it

`postUpgradeTasks` and `allowedCommands` are self-hosted-only, so this needs a
self-hosted run with the command allowed:

```bash
RENOVATE_ALLOWED_COMMANDS='["^\\./post-upgrade\\.sh$"]'
```

Then check the branch Renovate pushes:

```bash
git show renovate/github.com-google-uuid-1.x:lib/go.sum | tail -1   # marker present
git show renovate/github.com-google-uuid-1.x:app/go.sum | tail -1   # marker missing
```

## Notes

The marker line makes `go.sum` invalid to the Go toolchain. That does not affect
the reproduction, because nothing runs `go` after `postUpgradeTasks`. A marker is
used instead of a real `go mod tidy` so that "what the script wrote" and "what
got committed" are trivially comparable.
