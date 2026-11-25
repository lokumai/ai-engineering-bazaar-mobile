# Review 8, finding 5: R8 shrinks the release and keeps every name, so a native Android crash or ANR reaches Sentry with
# the app's own frames (Speech, ListenService) readable, with no mapping to upload and keep per build. Flutter's Gradle
# plugin adds this file to the release's rules when it is here.
-dontobfuscate

# Opus review 11, UX finding 1: R8 (full mode since AGP 9) dropped the no-argument constructors of ML Kit's component
# registrars, which Firebase's component runtime builds by reflection, so the code scanner's client threw at the
# activity's start and the release closed on every launch. Every registrar keeps its constructor.
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
