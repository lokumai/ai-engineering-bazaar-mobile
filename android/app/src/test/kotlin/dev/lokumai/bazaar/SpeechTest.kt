package dev.lokumai.bazaar

import android.speech.tts.TextToSpeech
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Which of the engine's answers mean a voice for a language ([Speech]). */
class SpeechTest {
    @Test
    fun aLanguageAvailableInAnyFormHasAVoice() {
        assertTrue(Speech.available(TextToSpeech.LANG_AVAILABLE))
        assertTrue(Speech.available(TextToSpeech.LANG_COUNTRY_AVAILABLE))
        assertTrue(Speech.available(TextToSpeech.LANG_COUNTRY_VAR_AVAILABLE))
    }

    @Test
    fun aLanguageMissingOrNotSupportedHasNone() {
        // Persian is often missing its data: no voice, and no Listen.
        assertFalse(Speech.available(TextToSpeech.LANG_MISSING_DATA))
        assertFalse(Speech.available(TextToSpeech.LANG_NOT_SUPPORTED))
    }
}

/** Which installed voice reads a module ([Speech.best]), and how a text's utterance id reads back ([Speech.parse]). */
class SpeechVoiceTest {
    private fun voice(
        language: String = "tr",
        country: String = "TR",
        quality: Int = 300,
        latency: Int = 300,
        network: Boolean = false,
        installed: Boolean = true,
    ) = Speech.VoiceFacts(language, country, quality, latency, network, installed)

    @Test
    fun theHighestQualityInstalledVoiceOfTheLanguageWins() {
        val voices = listOf(voice(quality = 300), voice(quality = 500), voice(language = "en", quality = 500))
        assertEquals(1, Speech.best(voices, "tr", "TR"))
    }

    @Test
    fun aVoiceNeedingTheNetworkOrNotInstalledIsPassedOver() {
        val voices = listOf(voice(quality = 300), voice(quality = 500, network = true), voice(quality = 500, installed = false))
        assertEquals(0, Speech.best(voices, "tr", "TR"))
    }

    @Test
    fun theCountryComesBeforeQualityAndTheQuickerBeforeTheSlower() {
        val voices = listOf(voice(country = "CY", quality = 500), voice(quality = 300, latency = 400), voice(quality = 300, latency = 200))
        assertEquals(2, Speech.best(voices, "tr", "TR"))
    }

    @Test
    fun noVoiceOfTheLanguageIsNone() {
        assertNull(Speech.best(listOf(voice(language = "en")), "fa", "IR"))
    }

    @Test
    fun anUtteranceIdReadsBackItsSpeakItsPlaceWhetherItIsTheLastAndItsPiece() {
        assertEquals(Speech.Part(7, 3, true, 0, 1), Speech.parse(Speech.utterance(7, 3, last = true)))
        assertEquals(Speech.Part(7, 0, false, 1, 3), Speech.parse(Speech.utterance(7, 0, last = false, piece = 1, pieces = 3)))
        assertNull(Speech.parse("7"))
        assertNull(Speech.parse("gap"))
        assertNull(Speech.parse(null))
    }

    @Test
    fun aTextsStartIsItsFirstPiecesAndItsEndItsLastPieces() {
        val first = Speech.Part(1, 0, true, 0, 2)
        val second = Speech.Part(1, 0, true, 1, 2)
        assertEquals(true to false, first.starts to first.ends)
        assertEquals(false to true, second.starts to second.ends)
    }
}

/** A text longer than the engine takes, said in pieces ([Speech.pieces], plan 18.4). */
class SpeechPiecesTest {
    @Test
    fun aTextThatFitsIsOnePiece() {
        assertEquals(listOf("One. Two."), Speech.pieces("One. Two.", 20))
    }

    @Test
    fun aLongTextEndsEachPieceAtASentencesEnd() {
        assertEquals(listOf("One two three.", "Four five six."), Speech.pieces("One two three. Four five six.", 20))
    }

    @Test
    fun withNoSentenceEndInReachItEndsAtASpace() {
        assertEquals(listOf("aaaa bbbb cccc", "dddd"), Speech.pieces("aaaa bbbb cccc dddd", 15))
    }

    @Test
    fun aWordLongerThanAPieceIsCut() {
        assertEquals(listOf("abcde", "fghij", "k"), Speech.pieces("abcdefghijk", 5))
    }

    @Test
    fun persianSentencesEndAtTheirOwnMark() {
        val pieces = Speech.pieces("یک دو سه؟ چهار پنج شش", 12)
        assertEquals("یک دو سه؟", pieces.first())
        assertTrue(pieces.all { it.length <= 12 })
    }
}
