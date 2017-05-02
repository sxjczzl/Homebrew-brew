# Contributing to Homebrew
First time contributing to Homebrew? Read our [Code of Conduct](https://github.com/Homebrew/brew/blob/master/CODEOFCONDUCT.md#code-of-conduct).

### Report a bug

* run `brew update` (twice)
* run and read `brew doctor`
* read [the Troubleshooting Checklist](http://docs.brew.sh/Troubleshooting.html)
* open an issue on the formula's repository or on Homebrew/brew if it's not a formula-specific issue

### Propose a feature

* open an issue with a detailed description of your proposed feature, the motivation for it and alternatives considered. Please note we may close this issue or ask you to create a pull-request if this is not something we see as sufficiently high priority.

### Add a command
* add Library/Homebrew/dev-cmd/new_command.rb (or other locations for non dev commands)
* edit completions/zsh/_brew
* run `brew man` after editing (test with `export MANPATH=$(brew --prefix)/share/man && man new_command`)
* submit PR

Thanks!
