# Review 8, finding 5: R8 shrinks the release and keeps every name, so a native Android crash or ANR reaches Sentry with
# the app's own frames (Speech, ListenService) readable, with no mapping to upload and keep per build. Flutter's Gradle
# plugin adds this file to the release's rules when it is here.
-dontobfuscate
