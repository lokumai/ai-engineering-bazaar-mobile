package dev.lokumai.bazaar

import android.speech.tts.TextToSpeech
import org.junit.Assert.assertFalse
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
