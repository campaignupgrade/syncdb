# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive README.md with full documentation
- MIT License (LICENSE file)
- Authors section in README
- Conditional framework detection using `wp cli has-command`
- Support for vanilla WordPress installations
- Compatibility with Flywheel hosting
- CHANGELOG.md to track version history
- Bash strict mode (`set -euo pipefail`) for better error handling
- Input validation functions (`validate_url`, `validate_remote`, `validate_path`)
- Optional `_local_url` config variable for manual URL override
- Auto-detection of local URL from `.lando.yml` when database doesn't exist

### Changed
- Improved SpinupWP cache purge - now conditionally checks if command exists
- Improved Acorn view commands - now conditionally checks if command exists
- Replaced old readme with comprehensive README.md
- Enhanced error handling to prevent failures on non-Bedrock projects
- All variables now properly quoted throughout to prevent command injection
- Destination URL now retrieved before import to avoid incorrect values
- Non-critical cleanup operations now use `|| true` for graceful failures
- Directory existence checks added before all operations

### Fixed
- Script no longer fails when SpinupWP plugin is not available
- Script no longer fails when Acorn (Bedrock/Sage) is not available
- Framework-specific commands now gracefully skip when not available
- Fixed path validation regex to properly detect directory traversal attempts
- Added file existence checks before deletion to prevent errors

### Security
- All variables properly quoted to prevent command injection vulnerabilities
- Removed `StrictHostKeyChecking=no` from SSH/rsync commands
- Added URL validation to block shell injection characters
- Added remote validation to whitelist allowed SSH hosts
- Added path validation to prevent directory traversal attacks

## [0.3.0] - 2025-11-26

### Added
- Version-controlled config support from parent repo (`dev/config/syncdb.sh`)
- Fallback to legacy local config (`options.sh`) for backward compatibility
- Clear error messages when configuration is not found

### Changed
- Configuration now prioritizes parent repo config over local config
- Improved configuration file detection and error handling

## [0.2.1] - 2024-04-10

### Added
- SpinupWP cache purge commands (`wp spinupwp cache purge-site`)
- Support for SpinupWP hosting environments

## [0.2.0] - 2024-02-01

### Changed
- Merged development branch improvements
- Enhanced error handling in WordPress commands

### Fixed
- Improved error handling in functions.sh
- Better handling of WordPress command errors

## [0.1.2] - 2024-01-23

### Changed
- Updated error handling in WordPress commands in functions.sh

## [0.1.1] - 2023-05-15

### Changed
- Removed options.sh from repository tracking
- Added .gitignore to prevent committing local configuration

### Added
- options.sh.example file for reference
- .gitignore to exclude local options file

## [0.1.0] - 2023-05-07

### Added
- Initial release
- Core database synchronization functionality
- SSH-based remote database operations via WP-CLI
- Interactive menu system for source/destination selection
- Automatic URL search-replace
- Support for Lando local development
- rsync-based file transfers
- Automatic cleanup of temporary database dumps
- Connection testing functionality

[Unreleased]: https://github.com/campaignupgrade/syncdb/compare/f6a9d55...HEAD
[0.3.0]: https://github.com/campaignupgrade/syncdb/commit/f6a9d55
[0.2.1]: https://github.com/campaignupgrade/syncdb/commit/2ee9359
[0.2.0]: https://github.com/campaignupgrade/syncdb/commit/5f8d8bf
[0.1.2]: https://github.com/campaignupgrade/syncdb/commit/7f7b5ad
[0.1.1]: https://github.com/campaignupgrade/syncdb/commit/0785066
[0.1.0]: https://github.com/campaignupgrade/syncdb/commit/0cfec7e
