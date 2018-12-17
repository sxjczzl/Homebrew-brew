# Skip to content
 
Search or jump to…

Pull requests
Issues
Marketplace
Explore
 @oscarg933 Sign out
You are over your private repository plan limit (4 of 0). Please upgrade your plan, make private repositories public, or remove private repositories so that you are within your plan limit.
Your private repositories have been locked until this is resolved. Thanks for understanding. You can contact support with any questions.
0
0 157 oscarg933/codezilla
forked from Asiatik/codezilla
 Code  Pull requests 0  Projects 0  Wiki  Insights  Settings
 zap codezilla zap One giant 🦖 collection of algorithms & design patterns.
 126 commits
 2 branches
 0 releases
 61 contributors
 MIT
 C++ 46.2%	 Java 36.8%	 Python 6.8%	 JavaScript 2.6%	 Shell 2.0%	 C 1.9%	 Other 3.7%
 Pull request   Compare This branch is 2 commits ahead of Asiatik:master.
@oscarg933
oscarg933 Update add-algorithm.md
Latest commit 0d4cc87  10 minutes ago
Type	Name	Latest commit message	Commit time
.github	Update add-algorithm.md	10 minutes ago
Data Structures	Fixes Asiatik#326 - Added documentation for linked lists (Asiatik#327)	2 months ago
Dynamic Programming	added code for best time to buy sell stock (Asiatik#136)	2 months ago
Graphs	Add DFS in python (Asiatik#302)	2 months ago
Greedy	Changed folder structure (Issue Asiatik#52) (Asiatik#53)	3 months ago
Https	Create Codecov.io.patch	10 minutes ago
JS Design Patterns	Changed folder structure (Issue Asiatik#52) (Asiatik#53)	3 months ago
Java Design Patterns	feat(Abstract Factory): added new Implementation for Abstract Factory…	2 months ago
Machine Learning	Implemented gradient descent in C++ (Asiatik#352)	2 months ago
Maths	Fix Asiatik#361: Add Fibonacci for C++ (Asiatik#362)	2 months ago
Searching	Added Linear Search and Binary Search in Javascript	a month ago
Sorting	Update InsertionSort.cpp (Asiatik#299)	2 months ago
String Manipulation	Implemented KMP in C++ (Asiatik#332)	2 months ago
.gitignore	Add .gitignore (Asiatik#155)	2 months ago
CODE_OF_CONDUCT.md	Create CODE_OF_CONDUCT (Asiatik#55)	3 months ago
CONTRIBUTING.md	updated runme.bh (Asiatik#254)	2 months ago
Fibonacci_series.py	Fibonacci Series in python (Asiatik#346)	2 months ago
LICENSE	Added Contributing.md (Issue 49) (Asiatik#50)	3 months ago
LL.java	Linked List Implementation (Asiatik#312)	2 months ago
README.md	Update README.md	2 months ago
heap in java	Create heap in java (Asiatik#189)	2 months ago
runme.bh	updated runme.bh (Asiatik#254)	2 months ago
 README.md
codezilla
License: MIT Gitter

codezilla 🦖 One giant collection of algorithms & design patterns.

The pandora box of algorithms and data structures

Feel free to contribute. Create an issue, let others know which algorithm/data structure you are planning to add. Fork the repo. And make a PR!

The goal is to create a codebase for developers to access. Later we aim to develop extensions using this codebase to support multiple IDEs.

How To Contribute to This Project
Here are 3 quick and painless steps to contribute to this project:

Star this repository to show your support for Asiatik

Add a a program to implement an algorithm in any language. To do so, first create an issue with the task you are doing, for example: "Issue - creating bubble sort in C". Create a pull request in response to that issue and finally submit it for review.

Name your branch Like #23 Add Bubble Sort in C.

Also create a directory for any new algorithm if it doesn't exist. eg. observable_pattern, bubble_sort. Inside these directories you can create a folder for the programming language you want to add. And finally add your own file named program_name.language_extension (bubble_sort.cpp) Create a commit of the form - fixes #(issue_number)

Make sure you adhere to the algorithm/language/file folder structure while adding code.

Easiest way (Recommended) star -You can run bash runme.bh on your terminal to make the appropriate file structure

Additionally we recommend using standard convention for your language such as indentation and variable naming while writing the algorithm. Useful comments will be a help. Finally, if you can write tests for you code, we urge you to do so.

Finally, wait for it to be merged!
Getting Started
Fork this repository (Click the Fork button in the top right of this page, click your Profile Image)

Clone your fork down to your local machine

$ git clone https://github.com/Username/codezilla.git
For e.g:-

$ git clone https://github.com/Anujg935/codezilla.git
in the above example Anujg935 is the username of the user who is forking the repository.

Create a branch

$ git checkout -b branch-name
Make your changes

Commit and Push

$ git add filename 
$ git commit -m 'commit message'
$ git push origin branch-name
Create a New Pull Request from your forked repository (Click the New Pull Request button located at the top of your repo)

Wait for your PR review and merge approval!

Star this repository to show your support for Asiatik

Don't forget to include the comments as seen above. Feel free to include additional information about the language you chose in your comments too! Like a link to a helpful introduction or tutorial.

Reference Links
Tutorial: Creating your first pull request

Managing your Forked Repo

Syncing a Fork

Keep Your Fork Synced

Awesome README examples Awesome

Github-Flavored Markdown

Additional References Added By Contributors
GitHub license explained
© 2018 GitHub, Inc.
Terms
Privacy
Security
Status
Help
Contact GitHub
Pricing
API
Training
Blog
About
Press h to open a hovercard with more details.

# Homebrew
[![GitHub release](https://img.shields.io/github/release/Homebrew/brew.svg)](https://github.com/Homebrew/brew/releases)

Features, usage and installation instructions are [summarised on the homepage](https://brew.sh). Terminology (e.g. the difference between a Cellar, Tap, Cask and so forth) is [explained here](https://docs.brew.sh/Formula-Cookbook#homebrew-terminology).

## What Packages Are Available?
1. Type `brew search` for a list.
2. Or visit [formulae.brew.sh](https://formulae.brew.sh) to browse packages online.
3. Or use `brew search --desc <keyword>` to browse packages from the command line.

## More Documentation
`brew help`, `man brew` or check [our documentation](https://docs.brew.sh/).

## Troubleshooting
First, please run `brew update` and `brew doctor`.

Second, read the [Troubleshooting Checklist](https://docs.brew.sh/Troubleshooting).

**If you don't read these it will take us far longer to help you with your problem.**

## Contributing
[![Azure Pipelines](https://img.shields.io/vso/build/Homebrew/56a87eb4-3180-495a-9117-5ed6c79da737/1.svg)](https://dev.azure.com/Homebrew/Homebrew/_build/latest?definitionId=1)
[![Codecov](https://img.shields.io/codecov/c/github/Homebrew/brew.svg)](https://codecov.io/gh/Homebrew/brew)

We'd love you to contribute to Homebrew. First, please read our [Contribution Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md#code-of-conduct).

We explicitly welcome contributions from people who have never contributed to open-source before: we were all beginners once! We can help build on a partially working pull request with the aim of getting it merged. We are also actively seeking to diversify our contributors and especially welcome contributions from women from all backgrounds and people of colour.

A good starting point for contributing is running `brew audit --strict` with some of the packages you use (e.g. `brew audit --strict wget` if you use `wget`) and then read through the warnings, try to fix them until `brew audit --strict` shows no results and [submit a pull request](https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request). If no formulae you use have warnings you can run `brew audit --strict` without arguments to have it run on all packages and pick one.

Alternatively, for something more substantial, check out one of the issues labeled `help wanted` in [Homebrew/brew](https://github.com/homebrew/brew/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22) or [Homebrew/homebrew-core](https://github.com/homebrew/homebrew-core/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22).

Good luck!

## Security
Please report security issues to our [HackerOne](https://hackerone.com/homebrew/).

## Who Are You?
Homebrew's lead maintainer is [Mike McQuaid](https://github.com/mikemcquaid).

Homebrew's project leadership committee is [Mike McQuaid](https://github.com/mikemcquaid), [Misty De Meo](https://github.com/mistydemeo) and [Markus Reiter](https://github.com/reitermarkus).

Homebrew/brew's other current maintainers are [Claudia](https://github.com/claui), [Michka Popoff](https://github.com/imichka), [Shaun Jackman](https://github.com/sjackman), [Chongyu Zhu](https://github.com/lembacon), [Vitor Galvao](https://github.com/vitorgalvao), [Misty De Meo](https://github.com/mistydemeo), [Gautham Goli](https://github.com/GauthamGoli), [Markus Reiter](https://github.com/reitermarkus), [Steven Peters](https://github.com/scpeters), [Jonathan Chang](https://github.com/jonchang) and [William Woodruff](https://github.com/woodruffw).

Homebrew/brew's Linux support (and Linuxbrew) maintainers are [Michka Popoff](https://github.com/imichka) and [Shaun Jackman](https://github.com/sjackman).

Homebrew/homebrew-core's other current maintainers are [Claudia](https://github.com/claui), [Michka Popoff](https://github.com/imichka), [Shaun Jackman](https://github.com/sjackman), [Chongyu Zhu](https://github.com/lembacon), [Izaak Beekman](https://github.com/zbeekman), [Sean Molenaar](https://github.com/SMillerDev), [Jan Viljanen](https://github.com/javian), [Jason Tedor](https://github.com/jasontedor), [Viktor Szakats](https://github.com/vszakats), [FX Coudert](https://github.com/fxcoudert), [Thierry Moisan](https://github.com/moisan), [Steven Peters](https://github.com/scpeters), [Misty De Meo](https://github.com/mistydemeo) and [Tom Schoonjans](https://github.com/tschoonj).

Former maintainers with significant contributions include [JCount](https://github.com/jcount), [commitay](https://github.com/commitay), [Dominyk Tiller](https://github.com/DomT4), [Tim Smith](https://github.com/tdsmith), [Baptiste Fontaine](https://github.com/bfontaine), [Xu Cheng](https://github.com/xu-cheng), [Martin Afanasjew](https://github.com/UniqMartin), [Brett Koonce](https://github.com/asparagui), [Charlie Sharpsteen](https://github.com/Sharpie), [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv), [Andrew Janke](https://github.com/apjanke), [Alex Dunn](https://github.com/dunn), [neutric](https://github.com/neutric), [Tomasz Pajor](https://github.com/nijikon), [Uladzislau Shablinski](https://github.com/vladshablinsky), [Alyssa Ross](https://github.com/alyssais), [ilovezfs](https://github.com/ilovezfs) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

## Community
- [discourse.brew.sh (forum)](https://discourse.brew.sh)
- [freenode.net\#machomebrew (IRC)](irc://irc.freenode.net/#machomebrew)
- [@MacHomebrew (Twitter)](https://twitter.com/MacHomebrew)

## License
Code is under the [BSD 2-clause "Simplified" License](LICENSE.txt).
Documentation is under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/).

## Donations
Homebrew is a non-profit project run entirely by unpaid volunteers. We need your funds to pay for software, hardware and hosting around continuous integration and future improvements to the project. Every donation will be spent on making Homebrew better for our users.

Please consider a regular donation through Patreon:

[![Donate with Patreon](https://img.shields.io/badge/patreon-donate-green.svg)](https://www.patreon.com/homebrew)

Alternatively, if you'd rather make a one-off payment:

- [Donate with PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=V6ZE57MJRYC8L)
- Donate by USA $ check from a USA bank:
  - Make check payable to "Software Freedom Conservancy, Inc." and place "Directed donation: Homebrew" in the memo field. Checks should then be mailed to:
    - Software Freedom Conservancy, Inc.
      137 Montague ST  STE 380
      BROOKLYN, NY 11201             USA
- Donate by wire transfer: contact accounting@sfconservancy.org for wire transfer details.

Homebrew is a member of the [Software Freedom Conservancy](https://sfconservancy.org) which provides us with an ability to receive tax-deductible, Homebrew earmarked donations (and [many other services](https://sfconservancy.org/members/services/)). Software Freedom Conservancy, Inc. is a 501(c)(3) organization incorporated in New York, and donations made to it are fully tax-deductible to the extent permitted by law.

## Sponsors
Our Xserve ESXi boxes for CI are hosted by [MacStadium](https://www.macstadium.com).

[![Powered by MacStadium](https://cloud.githubusercontent.com/assets/125011/22776032/097557ac-eea6-11e6-8ba8-eff22dfd58f1.png)](https://www.macstadium.com)

Our Jenkins CI installation is hosted by [DigitalOcean](https://m.do.co/c/7e39c35d5581).

![DigitalOcean](https://cloud.githubusercontent.com/assets/125011/26827038/4b7b5ade-4ab3-11e7-811b-fed3ab0e934d.png)

Our physical hardware is hosted by [Commsworld](https://www.commsworld.com).

![Commsworld powered by Fluency](https://user-images.githubusercontent.com/125011/30822845-1716bc2c-a222-11e7-843e-ea7c7b6a1503.png)

Our bottles (binary packages) are hosted by [Bintray](https://bintray.com/homebrew).

[![Downloads by Bintray](https://bintray.com/docs/images/downloads_by_bintray_96.png)](https://bintray.com/homebrew)

Secure password storage and syncing is provided by [1Password for Teams](https://1password.com/teams/) by [AgileBits](https://agilebits.com).

[![AgileBits](https://da36klfizjv29.cloudfront.net/assets/branding/agilebits-fcca96e9b8e815c5c48c6b3e98156cb5.png)](https://agilebits.com)

Homebrew is a member of the [Software Freedom Conservancy](https://sfconservancy.org).

[![Software Freedom Conservancy](https://sfconservancy.org/img/conservancy_64x64.png)](https://sfconservancy.org)
