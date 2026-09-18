# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security

- `cibuildgem release` no longer runs `gem push` through a shell. The `.gem` filenames it iterates over come from
  artifacts built in the unprivileged compile job, and interpolating them into a command string let shell syntax in a
  basename execute in the release job, after RubyGems credentials are configured. The filename is now passed as a
  single argv element.
- `cibuildgem release` now refuses a `.gem` whose basename holds anything other than letters, digits, dots, dashes
  and underscores, rather than publishing it. RubyGems restricts a gem's name, version and platform to those
  characters, so every filename `cibuildgem package` produces is accepted and one that is not was planted by
  something else running in the compile job.
- The action's `version` input is now passed to `gem install` through the step environment instead of being
  interpolated into the shell script. A workflow that wired the input to a value it did not control turned a version
  selector into arbitrary commands running in the job; the value now reaches `gem install` as a single argument and
  RubyGems rejects it if it is not a version.

## [0.3.0] - 2026-03-27

### Added

- The cibuildgem action has a new parameter "version". You can add this in the workflow to configure which version
  of the cibuildgem gem to use (defaults to latest published version on rubygems.org)

### Fixed

- You can now retry the publish step in case it failed. This was previously not possible because the retried job would
  fail if the previous one had already pushed **some** gems.

## [0.2.1] - 2026-01-09

### Fixed

- Gem that define a `test` rake task with a prerequisite `compile` task would make cibuildgem crash. This is now fixed.

## [0.2.0] - 2026-01-09

### Added

- Support Ruby 4. It is now possible to ship gem with precompiled binaries working on Ruby 4.
