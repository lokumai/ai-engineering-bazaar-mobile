# Store privacy answers

The answers for App Store Connect's App Privacy and Google Play's Data safety forms (plan 6.2).
They hold while the app sends crash reports only (README, Privacy). A change to what Sentry sends is a change here, in the iOS privacy manifest (`ios/Runner/PrivacyInfo.xcprivacy`), on Privacy and legal in the app and in the site's privacy note.

## What leaves the device

- A crash report to Sentry (`lokumai/ai-bazaar-mobile`, EU region), from a release built with the DSN: the error and its stack trace, the app's version, the device's model and system, and the app's last breadcrumbs, with personal details masked on the device.
- Sentry stores no IP address (project setting).
- No session, performance trace, route name, screenshot, analytics event, account or advertising identifier.
- The course download from the site on GitHub Pages, which logs IP addresses as GitHub's own record.

## App Store Connect: App Privacy

- Data collection: Yes, the app collects data.
- Data type: Diagnostics, Crash Data. No other type.
- Linked to the user's identity: No.
- Used for tracking: No.
- Purpose: App Functionality.
- Privacy policy URL: `https://ai-bazaar.lokum.dev/legend/#privacy`.

## Google Play: Data safety

- Does the app collect or share any of the required user data types: Yes.
- Data type: App info and performance, Crash logs. No other type.
- Collected: Yes. Shared: No (Sentry processes it as a service provider).
- Processed ephemerally: No.
- Required or optional: Required (the report is sent when the app crashes; a build without the DSN sends none).
- Purpose: App functionality.
- Encrypted in transit: Yes (HTTPS).
- Users can request deletion: Yes, by email to the address on Privacy and legal.
- Privacy policy URL: `https://ai-bazaar.lokum.dev/legend/#privacy`.
