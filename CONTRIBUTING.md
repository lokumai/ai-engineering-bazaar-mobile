# Contributing to AI Engineering Bazaar mobile

Thank you for helping. This app reads the AI Engineering Bazaar course; the course itself is written in the web repo, [lokumai/ai-engineering-bazaar](https://github.com/lokumai/ai-engineering-bazaar).

## Where a change belongs

- A mistake in a module's text, a translation or a diagram: open an issue or a pull request on the web repo. The app shows what the site publishes and takes it at its next refresh.
- Something the app shows wrong, a crash, a layout or an accessibility problem: open an issue here with the steps, the device and the app's language.
- A fact the app would need but the bundle does not carry: propose it to the web repo first. The app derives no fact the bundle does not publish (D111).

## Making a change

1. Fork the repo and clone your fork.
2. Read [CLAUDE.md](CLAUDE.md): it holds the layering rules, the record rules and the copy register, and the guards under `test/architecture/` enforce most of them.
3. Branch from `main`: `git checkout -b <short-name>`.
4. Keep each feature in its own folder under `lib/features/`; a feature imports no other feature, and shared code lives in `lib/shared/`.
5. Put every new string of the interface in all three ARB files under `lib/l10n/`, then run:

    ```shell
    fvm flutter pub get
    fvm dart run intl_utils:generate
    fvm dart format lib/generated --line-length=120
    ```

6. Give every fix a test that fails without it.
7. Run the gate before you push:

    ```shell
    fvm dart format . --line-length=120 --set-exit-if-changed && fvm flutter analyze && fvm flutter test --coverage && scripts/check_coverage.sh coverage/lcov.info 90
    ```

8. Open a pull request against `main` that says what changed and why, and links the issue it closes.

## Style

- Dart's style, formatted at 120 columns.
- Docs and strings in plain words; no em or en dashes.
- Small commits, each with a message that says what it does.

## Review

A maintainer reviews every pull request and may ask for changes. CI must pass before a merge.

## Questions

Open an issue in this repo.
