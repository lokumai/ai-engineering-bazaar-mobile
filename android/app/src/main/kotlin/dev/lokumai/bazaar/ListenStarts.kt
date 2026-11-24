package dev.lokumai.bazaar

/**
 * The starts and stops of [ListenService] (plan 20.1): Android ends an app that stops a service it asked to start before
 * the service has come to the foreground, so a stop asked for while a start is pending waits for it. Pure, so the JVM
 * tests run it (review 3, finding 11).
 */
class ListenStarts {
    /** Starts asked for that the service has not taken yet. */
    var pending = 0
        private set

    /** A stop asked for while a start was pending, done once the service is in the foreground. */
    var stopWhenStarted = false
        private set

    /** A start is asked for: a stop asked for before it is dropped. */
    fun asked() {
        stopWhenStarted = false
        pending++
    }

    /** Android refused the start asked for: it will never be taken. */
    fun refused() {
        if (pending > 0) pending--
    }

    /** A stop is asked for: true when it may be done now, false when it waits for a pending start. */
    fun stop(): Boolean {
        if (pending > 0) {
            stopWhenStarted = true
            return false
        }
        return true
    }

    /**
     * The service took a start and came to the foreground, or not ([foreground]): true when it must stop itself now,
     * as it must when Android refused the foreground, or when a stop waited for the last start pending.
     */
    fun taken(foreground: Boolean): Boolean {
        if (pending > 0) pending--
        if (!foreground) {
            stopWhenStarted = false
            return true
        }
        if (pending == 0 && stopWhenStarted) {
            stopWhenStarted = false
            return true
        }
        return false
    }
}
