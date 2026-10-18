# Changelog

## v1.2 (2026-10-18)

### Fixed
- `score` output was always empty: the score was written to the review step's
  output but read from the results step. The results step now writes the score
  itself after fetching completed results.
- `review.sh` no longer crashes with an unclear error when `jq` is missing on
  the runner - it fails fast with an explicit error message.
- `STATUS` is initialized before the wait loop, so very short timeouts no
  longer trigger an unbound variable error under `set -u`.

### Changed
- `.gitignore` replaced the empty placeholder with a real ignore list.

## v1.1 (2026-07-13)

- Initial public release of the composite action: review request, wait for
  completion, Step Summary output, and optional PR comment.
