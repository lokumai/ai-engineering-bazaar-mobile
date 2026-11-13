# Store privacy answers

The answers for App Store Connect's App Privacy and Google Play's Data safety forms (plan 6.2).
They hold for a release built with the Sentry DSN, which sends what the owner chose on 2026-11-13: crash reports, hangs, how long the app took to open, release-health sessions and Report a problem.
A change to what Sentry sends is a change here, in the iOS privacy manifest (`ios/Runner/PrivacyInfo.xcprivacy`), on Privacy and legal in the app (`privacy_crash`) and in the site's privacy note.

## What leaves the device

- **Crash reports**: the error and its stack trace, the app's version, the device's model and system, and the app's last breadcrumbs, with emails and secrets masked on the device.
- **Hangs**: when the app froze (ANR on Android, app hang on iOS), with the threads' stack traces and the device. On iOS sentry-cocoa sends these itself; the breadcrumbs in them are the Dart side's, already masked.
- **App start**: one transaction with how long the app took to open, cold or warm. It names no route. Every other transaction is dropped on the device (`sentryBeforeSendTransaction`).
- **Sessions** (release health): when the app opened and closed, whether it crashed, the release and environment, and a random id of the installation made by the Sentry SDK. No text, no reading, no quiz answer.
- **Report a problem**: the text the reader writes and sends, with emails and secrets masked, the app's version and the device. No name and no contact email are asked.
- Sentry stores no IP address (project `lokumai/ai-bazaar-mobile`, EU region, server-side scrubbing on).
- Not sent: what the reader reads or answers, route names, screenshots, view hierarchy, Session Replay, an account, an advertising id.
- The course download from the site on GitHub Pages, which logs IP addresses as GitHub's own record.

## App Store Connect: App Privacy

Data collection: Yes, the app collects data. For every type below: not linked to the user's identity, not used for tracking, purpose App Functionality.

| Category | Type | What it is here |
|---|---|---|
| Diagnostics | Crash Data | Crash reports |
| Diagnostics | Performance Data | How long the app took to open |
| Diagnostics | Other Diagnostic Data | Hangs |
| Usage Data | Product Interaction | The sessions of release health (the app's launches) |
| User Content | Customer Support | Report a problem |

Privacy policy URL: `https://ai-bazaar.lokum.dev/legend/#privacy`.

## Google Play: Data safety

- Does the app collect or share any of the required user data types: Yes.
- Is all user data encrypted in transit: Yes (HTTPS).
- Can users request that their data be deleted: Yes, by email to the address on Privacy and legal.
- Shared: No for every type (Sentry processes the data as a service provider).

| Category | Type | Collected | Ephemeral | Required | Purpose |
|---|---|---|---|---|---|
| App info and performance | Crash logs | Yes | No | Required | App functionality |
| App info and performance | Diagnostics | Yes | No | Required | App functionality |
| App activity | App interactions | Yes | No | Required | App functionality |
| App activity | Other user-generated content | Yes | No | Optional | App functionality |
| Device or other IDs | Device or other IDs | Yes | No | Required | App functionality |

- Diagnostics covers the hangs and the app start; App interactions covers the sessions; Other user-generated content is Report a problem, sent only when the reader sends one; Device or other IDs is the random installation id of the sessions, which Google counts like a Firebase installation id.
- Privacy policy URL: `https://ai-bazaar.lokum.dev/legend/#privacy`.
