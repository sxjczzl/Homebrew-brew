# Governance

**This document is primarily for maintainers.** These people have **write
access** to Homebrew’s repository and help merge the contributions of
others.

_Modifying this document in a way that has tangible consequences requires an
affirmative vote from a simple majority of the Project Leadership Committee._

## Structure

Homebrew has a three-tier system of governance. First and foremost is the
**lead maintainer**, followed by the Project Leadership Committee _(PLC)_, and
lastly regular maintainers.

### The Lead Maintainer

The lead maintainer is effectively the "face of Homebrew" and the primary point
of contact between Homebrew and external bodies, such as Bintray or the Software
Freedom Conservancy, as well as being responsible for managing the project's
finances. There is only ever one lead maintainer for the entire project.

The lead maintainer is expected to largely direct the priorities and aims of the
project, and consequently has significant influence over whether a suggested
feature/change gains traction or whether a pull request is merged. It is the
responsibility of the lead maintainer to ensure changes to Homebrew are
beneficial to the health of the project or the experience of its users, and to
ensure Homebrew does not introduce unnecessary inconsistencies that could
confuse contributors or users.

The lead maintainer is not expected to spend a significant amount of time
handling basic pull requests, such as version bumps to formulae. The lead
maintainer is essentially a maintainer for other maintainers; reviewing their
pull requests and offering advice where necessary, approving changes and being
willing to answer questions when maintainers are unsure on why something was
implemented a certain way or how something works.

As a necessary part of this project management the lead maintainer is entrusted
with a certain amount of "hard power"; these powers include the ability to
override other maintainers and to cast a deciding vote where an impasse has been
reached. The lead maintainer may also interject in discussions between
maintainers to prevent conflict and maintain team harmony, and generally is
welcome to provide an opinion in any discussion they wish to involve themselves
in.

### The Project Leadership Committee

The PLC consists exclusively of the owners of Homebrew's GitHub organisation.
These people are regularly active in both contribution and discussion between
maintainers, whether in public issues on GitHub or privately on Homebrew's
Slack channel, and have maintained Homebrew for a total of at least a year
prior to joining the PLC. Membership is not automatic and is only offered after
an affirmative simple-majority vote of the PLC.

There is an expectation that PLC members will go above and beyond the
responsibilities of regular maintainers. They should, for example, assist the
lead maintainer with sysadmin work; this involves working to keep Homebrew's CI
up-to-date, Homebrew's hardware secure and ensuring the Homebrew
[website](https://brew.sh) remains up-to-date with TLS configuration and
certification.

The PLC is a formal body that primarily operates to communicate and resolve,
with the Software Freedom Conservancy, any legal and administrative issues that
may arise. Due to the legal involvement of this body members of the PLC cannot
be anonymous, and must be willing to submit various details, including their
real name, to the Software Freedom Conservancy.

The PLC also has two more technical roles. The first of these roles is to vote
on issues that cannot be resolved in regular discussion between maintainers,
such as whether to approve a controversial idea or feature. PLC votes on
technical issues should be used sparingly, reserved normally for issues that
will regularly impact the vast majority of maintainers.

The second of these roles is to provide checks and balances. The PLC as a body
has an obligation to ensure power is being exercised carefully and fairly by all
maintainers, including the lead maintainer. The lead maintainer must always be
part of the PLC, but [cannot always](#accountability) vote on every issue that
arises.

### Regular Maintainers

Regular maintainers are people who have commit access to Homebrew but are not
expected or obligated to help with legal, technical or administrative issues
that arise impacting the project itself. Regular maintainers can be members of
multiple GitHub repositories or may only be maintainers of one repository, such
as `homebrew/livecheck`.

Regular maintainers spend almost all of their time around Homebrew providing
code review or submitting pull requests of their own, do not routinely have
access to Homebrew's hardware _(but can be granted access)_ and are not expected
to do sysadmin work. Regular maintainers have access to CI for the purposes of
build queue control and triggering jobs, and have the ability to manually
request a rebuild via `@BrewTestBot test this please`.

## Accountability

Everyone is accountable for their words and actions, or lack thereof, in
Homebrew, and nobody has unchecked power or influence. The below list covers
various situations that may arise and how to handle them.

### The Lead Maintainer Position and The Holder Of That Position

At least once a year, provisionally September 14th, the PLC is mandated to
affirm or withhold its consent for the lead maintainer role to exist in its
current form as a distinct entity. The lead maintainer may vote on this issue.
In the event of a tie regular maintainers are asked to vote on the issue and
collectively act as the sole tie-breaking vote.

On the same day the PLC is additionally mandated to vote on whether to affirm
or withhold its consent for the current occupant of the lead maintainer role to
remain in post. The lead maintainer _may not_ participate in this vote, and
again in the event of a tie regular maintainers will be asked to provide a
collective tiebreaker.

Neither of the above bar any member of the PLC calling a vote on either issue
at an earlier point in time, although doing so should be considered frowned
upon in all but the most severe of circumstances. In both votes a simple
majority suffices as a valid determination of the will of the PLC.

If the lead maintainer position becomes vacant for any reason the PLC is
mandated to fill the vacancy, unless a vote is held to absorb the position.
Any maintainer or member of the PLC can nominate a new lead maintainer, but
confirming a new lead maintainer requires every member of the PLC to vote
and 2/3 of those votes to be in the affirmative.

### Maintainer Pull Requests and Issues

Maintainers may not close other maintainer's Pull Requests or Issues without
the consent of the maintainer in question. The two exceptions of this rule are:

_Inactivity_: If a Pull Request or Issue is inactive for 28 days, any maintainer
is welcome to nudge the maintainer who opened the PR/Issue for an update on
where things stand, and if one is not provided within two days the issue can be
closed by any maintainer. If the maintainer who opened the PR/Issue wishes to
return to it later they are welcome to reopen the PR/Issue.

_Simple Changes_: If a maintainer submits, for example, a minor documentation
tweak to `homebrew/brew` or a simple version bump to `homebrew/core` any
maintainer is welcome to merge that in without waiting for the original
maintainer to do so. If maintainers object to this they should add the
`do not merge` label to the PR/Issue. That label may be ignored if the issue
is an urgent security fix or critical to the continued function of Homebrew's
CI.

Maintainers should not routinely revert the work of other maintainers without
first discussing what the issue is with that maintainer. However, if the
problem is significant and the original maintainer cannot be reached within an
hour any maintainer may revert a problematic commit. It is recommended to ping
the original maintainer into any revert PR so they can comment later if they
wish to, and so they're aware of the revert without having to go fishing in the
commit log.

### Maintainer Conduct

Maintainers are expected to adhere to
[Homebrew's Code of Conduct](https://github.com/Homebrew/brew/blob/master/CODE_OF_CONDUCT.md),
whether in public or private communication.

Abusive behaviour towards other maintainers, contributors or users will not be
tolerated; the maintainer will be given a warning and if their behaviour
continues either the lead maintainer or any member of the PLC can initiate a
maintainer-wide simple-majority vote on dismissing that maintainer. The
maintainer in question is allowed to provide a statement to the group but
otherwise is not allowed to interfere in the discussion or partake in the vote.

Constructive disagreement is both encouraged and welcome, where it benefits the
project. Technical discussions should occur in public to ensure that any
decision reached is transparent to users and does not suffer from echo chamber
syndrome. Issues of a personal nature should be handled in Slack, where
necessary with the moderation of the lead maintainer or a member of the PLC.

If the decision reached seems to be lacking justification or is insufficiently
documented anyone is welcome to ask for clarification. No decisions can or
should be justified by an imposition of authority or unfair ownership over an
issue or aspect of Homebrew, and where discussions become overly-vigorous
maintainers should seek to calm the situation and apologise if the line
between spirited discussion and personal attacks was crossed. Regular crossing
of that line may trigger a team discussion on the future of the individual in
question.

### Suggesting and Inviting New Maintainers

Any maintainer can sponsor someone to become a Homebrew maintainer, but must
be willing to explain why the person should be invited to help maintain
Homebrew. Homebrew is always willing to have open, friendly discussions about
adding to the team, and if you see someone contributing regularly and to a
high standard you are encouraged to suggest them to the lead maintainer or
suggest them in the private Slack maintainer channel yourself.

An invitation should be extended to the individual suggested if a simple
majority of maintainers vote in support; at least 50% of the existing
maintainers must participate in the vote for it to be valid, and an invitation
can be withdrawn at any time prior to acceptance should an issue be discovered.

The process of inviting maintainers is documented
[here](New-Maintainer-Checklist.md#new-maintainer-checklist).

### Overriding The Lead Maintainer

The lead maintainer has broad authority over the direction of the project and
acceptability of suggested features or changes, as discussed earlier. This
authority should be respected and overridden rarely. Every reasonable effort
should be made to convince the lead maintainer of your viewpoint prior to
considering this formal mechanism, but in the event that the lead maintainer
pushes a course of action that the overwhelming majority of maintainers find
ill-advised or hostile for the health of the project any maintainer can initiate
a vote to override the lead maintainer.

This vote is explicitly **not** simple-majority. To override the lead maintainer
in, for example, `homebrew/core` you would require 2/3 of the maintainers of
that repository to achieve quorum. When quorum is achieved you again require 2/3
of the maintainers in that quorum to override the lead maintainer. In effect
this means that if `homebrew/core` has 15 maintainers, you require 10 of those
maintainers to participate in an override vote for it to be valid, and require
at least 6 of those 10 to vote affirmatively to achieve an override. If all 15
core maintainers vote you require 10 votes to override, and so on.

The lead maintainer may not vote for or against a motion to override their own
decision, and must respect the outcome of the vote.
