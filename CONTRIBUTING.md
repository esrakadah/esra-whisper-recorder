# Contributing

This is a small, single-purpose CLI tool, so contribution scope is intentionally
narrow.

## Quick fixes — just open a PR

- Typos or unclear steps in the README.
- A fix for a `record_and_transcribe.sh` bug on a specific macOS/Whisper version.

## Anything bigger — open an issue first

- Adding a new dependency or model size.
- Supporting a platform other than macOS.

## Ground rules

- Keep it offline-first: no step should require a network call after the initial
  setup in the README.
- Keep the script dependency-light (SoX + Whisper); avoid adding a package manager
  or framework for what is deliberately a one-file tool.
