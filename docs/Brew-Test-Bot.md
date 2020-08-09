---
logo: https://brew.sh/assets/img/brewtestbot.png
image: https://brew.sh/assets/img/brewtestbot.png
---

Brew Test Bot
=============

Homebrew comes with a comprehensive suite of tools that lets you
validate that both your homebrew installation is working and prove that
a formula is working.

Homebrew Test Bot uses these tools to simplify the automation of your
formula publishing process including Checking your installation,
Checking your Formula, and Building and uploading binaries.

`brew test-bot` is the name for the automated review and testing system
funded by [our Kickstarter in
2013](https://www.kickstarter.com/projects/homebrew/brew-test-bot).

It comprises three Mac Pros hosting virtual machines that run the
[`test-bot.rb`](https://github.com/Homebrew/homebrew-test-bot/) external
command to perform automated testing of commits to the master branch,
pull requests and custom builds requested by maintainers.

Pull Requests
-------------

The bot automatically builds pull requests and updates their status
depending on the result of the job.

For example, a job which has been queued but not yet completed will have
a section in the pull request that looks like this:

![Triggered Pull
Request](assets/img/docs/brew-test-bot-triggered-pr.png)

------------------------------------------------------------------------

A failed build looks like this:

![Failed Pull Request](assets/img/docs/brew-test-bot-failed-pr.png)

------------------------------------------------------------------------

A passed build looks like this:

![Passed Pull Request](assets/img/docs/brew-test-bot-passed-pr.png)

------------------------------------------------------------------------

On failed or passed builds you can click the "Details" link to view the
result in GitHub Actions.

Usage for custom taps
---------------------

You can use this tool for custom taps too, or to locally to validate a
formula you're developing.

### Locally Validating a formula

If this is for a custom tap, first, tap the repository.

    brew tap "custom/tap"

Then make your changes.

    echo $YOUR_CHANGES > "$(brew --repo)/Library/Taps/custom/homebrew-tap/Formula/your-formula.rb"

Next, we can validate our changes, including testing and linting, and
dependency checks.

    brew test-bot "custom/tap/your-formula"

### Validating a formula change in GitHub actions

You are running on GitHub actions test-bot will try to fix any potential
problems in the homebrew repository deleting the `$(brew --repo)/Cellar`
before performing any operations. If you've intentionally made changes
there, they will be lost, what's more `--cleanup` is always passed.

When `--cleanup` is passed, we hard reset the taps to "origin/master",
as such your changes will need to be clonable from "master".

If you're using this tool for a personal tap, and as such won't have the
changes on `master` because you're validating a pull request, or want to
use another default branch, As a workaround, you can unset the
`GITHUB_ACTIONS` environment variable to stop this behaviour, and
manually triggering the clean-up steps.

    brew update-reset
    brew test-bot --cleanup --only-cleanup-before
    echo $YOUR_CHANGES > "$(brew --repo)/Library/Taps/custom/homebrew-tap/Formula/your-formula.rb"
    unset GITHUB_ACTIONS
    brew test-bot "custom/tap/your-formula"

### Building Binaries for that formula

Currently, we only support bintray as a destination for binaries.

    brew test-bot \
      --ci-upload \
      --bintray-org="your-org" \
      --root-url="https://dl.bintray.com/custom/bottles-repo" \
      --tap=custom/tap \
      --publish \
       custom/tap/your-formula

Remember to replace
"\[[[https://dl.bintray.com/custom/bottles-repo"](https://dl.bintray.com/custom/bottles-repo")](https://dl.bintray.com/custom/bottles-repo")\]([https://dl.bintray.com/custom/bottles-repo"](https://dl.bintray.com/custom/bottles-repo"))
with the path to your bottle location.

Then push the changes it's made to the tap to include the download
information in the formula.

    cd "$(brew --repo)/Library/Taps/custom/homebrew-tap"
    git push
