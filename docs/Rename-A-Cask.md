# Renaming a Cask

Sometimes software and casks need to be renamed. To rename a cask
you need to:

1. Rename the casks file and its class to a new cask. The new name must meet all the usual rules of cask naming. Fix any test failures that may occur due to the stricter requirements for new casks than existing casks (i.e. `brew audit --online --new --cask` must pass for that cask).

2. Create a pull request to the corresponding tap deleting the old cask file, adding the new cask file, and adding it to `cask_renames.json` with a commit message like `newack: renamed from ack`. Use the canonical name (e.g. `ack` instead of `user/repo/ack`).

A `cask_renames.json` example for a cask rename:

```json
{
  "ack": "newack"
}
```
