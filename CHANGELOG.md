# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
