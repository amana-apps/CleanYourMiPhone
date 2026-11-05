# Changelog

This project follows [Semantic Versioning](https://semver.org/).

## 0.1.0 (2026-11-05)

First public release.

- `check`, `scan`, `clean`, `restore`, `speed` and `version` commands
- Preview by default; removal needs `--apply` and a confirmation
- Package list backup before each removal
- Protected list that the script refuses to remove
- Warnings for apps that can't be restored
- Speed guide, offline tests and CI

The script has been tested against a fake `adb` only, not a real phone.
