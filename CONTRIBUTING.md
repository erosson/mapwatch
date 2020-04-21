## Contributing to Mapwatch

Happy to consider pull requests. Talk to @erosson before spending lots of time on one - accepting pull requests is not a sure thing, even when there's an open issue.

# Development

One-time setup (if this is broken, please talk to @erosson or file an issue):

* fork and clone the repository
* install [Node](https://nodejs.org/en/), [Yarn](https://yarnpkg.com/en/docs/install)
* most Mapwatch code is written in Elm, so install [Elm](https://guide.elm-lang.org/install.html). Configure your editor to handle Elm code and run [elm-format](https://github.com/avh4/elm-format) on save. I mostly use [Atom](https://atom.io/packages/language-elm).
* finally, run `yarn` and your repository should be ready to use

Developing:

* run the website locally: `yarn dev:www`. Most website code lives in `packages/www/src`
* create a production build of the website: `yarn build:www`
* create a production build everything: `yarn build`

# Release

Each git-push to the master branch is automatically built and deployed by [Travis-CI](https://travis-ci.org/github/mapwatch/mapwatch). [CI configuration](https://github.com/mapwatch/mapwatch/blob/master/.travis.yml).

The downloadable Electron app is a little more complex, and is less automated: https://www.electron.build/configuration/publish#recommended-github-releases-workflow

There should always be a *draft release* in progress, invisible to the public, on [the releases page](https://github.com/mapwatch/mapwatch/releases). CI keeps it updated with an executable from the latest build.

* When the draft release looks ready, click "publish". It becomes user-visible and the executable can't be changed anymore.
* Draft the next release, so CI can post previews of the next version:
  * Bump the version number in [electron's package.json](https://github.com/mapwatch/mapwatch/blob/master/packages/electron2/package.json), probably with `npm version patch`. Commit and push.
  * [Create a draft release on the releases page](https://github.com/mapwatch/mapwatch/releases). Name and tag should match the above package.json version, with a leading `v` - `v1.0.2`, for example.

# Translation and Localization

See [TRANSLATING.md](https://github.com/mapwatch/mapwatch/blob/master/TRANSLATING.md)

# Resources

[Analytics: recent referral traffic (you probably don't have permissions)](https://analytics.google.com/analytics/web/#/report/trafficsources-referrals/a119582500w176920100p175689790/_u.dateOption=last7days&explorer-table.secSegmentId=analytics.fullReferrer&explorer-table.plotKeys=%5B%5D&explorer-graphOptions.primaryConcept=analytics.totalVisitors&explorer-graphOptions.compareConcept=analytics.newVisits&_.useg=builtin1/)
