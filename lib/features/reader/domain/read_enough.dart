/// Whether a module counts as read, to be marked completed as it is left (the owner, 2026-11-18): read to its end, and
/// on the screen for at least a third of its [minutes] over every visit, so a quick scroll to the end is not a read.
bool readEnough({required bool reachedEnd, required int seconds, required int minutes}) =>
    reachedEnd && seconds * 3 >= minutes * 60;
