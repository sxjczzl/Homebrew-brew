# Contributing to Homebrew
First time contributing to Homebrew? Read our [Code of Conduct](https://github.com/Homebrew/brew/blob/master/CODEOFCONDUCT.md#code-of-conduct).

### Report a bug

* run `brew update` (twice)
* run and read `brew doctor`
* read [the Troubleshooting Checklist](https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/Troubleshooting.md#troubleshooting)
* open an issue on the formula's repository

### Propose a feature

* create a pull request in the [Homebrew Evolution](https://github.com/Homebrew/brew-evolution) repository using the [proposal template](https://github.com/Homebrew/brew-evolution/blob/master/proposal_template.md)

### Contribute code

* there are no universally applicable rules (a lot depend on the scope of your change)
* before you start coding, consider [proposing a feature](#propose-a-feature) (see above) or discussing the idea in an issue
* to learn how to structure your commits, consult the Git history of modified files
* [open a pull request](https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/How-To-Open-a-Homebrew-Pull-Request-(and-get-it-merged).md#how-to-open-a-homebrew-pull-request-and-get-it-merged) on this repository

### Improve help for `brew <command>`

* edit documentation comments in `Library/Homebrew/cmd/<command>.{rb,sh}`
  * check that the output of `brew help <command>` still looks sensible
* run `brew man` to regenerate the man page and its HTML version
  * check that the diff of these files is limited to the changed section (if it's not, this usually means some change broke the overall formatting)
  * check `man brew` and whether the man page renders as expected
* `git commit` with message `<command>: improve documentation` (or similar) and make sure to include all changed files
* [open a pull request](https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/How-To-Open-a-Homebrew-Pull-Request-(and-get-it-merged).md#how-to-open-a-homebrew-pull-request-and-get-it-merged) on this repository

Thanks!
