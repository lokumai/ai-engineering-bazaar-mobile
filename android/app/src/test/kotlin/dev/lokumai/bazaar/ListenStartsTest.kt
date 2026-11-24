package dev.lokumai.bazaar

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** The service's starts and stops ([ListenStarts], plan 20.1; review 3, finding 11). */
class ListenStartsTest {
    @Test
    fun aStopWithNoStartPendingIsDoneAtOnce() {
        val starts = ListenStarts()
        assertTrue(starts.stop())
        starts.asked()
        assertFalse(starts.taken(foreground = true))
        assertTrue(starts.stop())
    }

    @Test
    fun aStopWhileAStartIsPendingWaitsForTheForeground() {
        val starts = ListenStarts()
        starts.asked()
        assertFalse("Android ends an app that stops a service before its foreground", starts.stop())
        assertTrue(starts.stopWhenStarted)
        assertTrue("stops itself once in the foreground", starts.taken(foreground = true))
        assertFalse(starts.stopWhenStarted)
    }

    @Test
    fun aStopWaitsForTheLastOfSeveralStarts() {
        val starts = ListenStarts()
        starts.asked()
        starts.asked()
        assertFalse(starts.stop())
        assertFalse("one start still pending", starts.taken(foreground = true))
        assertTrue(starts.taken(foreground = true))
    }

    @Test
    fun aStartAfterAStopDropsTheStop() {
        val starts = ListenStarts()
        starts.asked()
        assertFalse(starts.stop())
        starts.asked()
        assertFalse(starts.stopWhenStarted)
        assertFalse(starts.taken(foreground = true))
        assertFalse(starts.taken(foreground = true))
    }

    @Test
    fun aRefusedStartIsNotWaitedFor() {
        val starts = ListenStarts()
        starts.asked()
        starts.refused()
        assertEquals(0, starts.pending)
        assertTrue(starts.stop())
    }

    @Test
    fun aRefusedForegroundStopsTheServiceAndForgetsTheWaitingStop() {
        val starts = ListenStarts()
        starts.asked()
        assertFalse(starts.stop())
        assertTrue(starts.taken(foreground = false))
        assertFalse(starts.stopWhenStarted)
        assertEquals(0, starts.pending)
    }

    @Test
    fun aTakenStartNeverCountsBelowZero() {
        val starts = ListenStarts()
        assertFalse(starts.taken(foreground = true))
        starts.refused()
        assertEquals(0, starts.pending)
    }
}
