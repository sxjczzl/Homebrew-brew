# Renaming a Cask

Sometimes software and casks need to be renamed. To rename a cask
you need to:

1. Rename the casks file and its class to a new cask. The new name must meet all the usual rules of formula naming. Fix any test failures that may occur due to the stricter requirements for new formulae than existing formulae (i.e. `brew audit --online --new-formula` must pass for that formula).

2. Create a pull request to the corresponding tap deleting the old formula file, adding the new formula file, and adding it to `cask_renames.json` with a commit message like `newack: renamed from ack`. Use the canonical name (e.g. `ack` instead of `user/repo/ack`).

A `cask_renames.json` example for a formula rename:

```json
{
  "ack": "newack"
}
```
