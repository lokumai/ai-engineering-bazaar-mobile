package dev.lokumai.bazaar

import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** A scan answers the Dart side once, though the install limit and Play services may both answer (review 3, finding 8). */
class CodeScannerTest {
    private class Answers : MethodChannel.Result {
        val got = mutableListOf<String>()

        override fun success(result: Any?) {
            got += "success $result"
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            got += "error $errorCode"
        }

        override fun notImplemented() {
            got += "notImplemented"
        }
    }

    @Test
    fun theFirstAnswerIsTheOnlyOne() {
        val answers = Answers()
        val once = CodeScanner.Once(answers)
        once.error("no-scanner", "module not in place after 60 s", null)
        once.success("https://example.test/transfer/#t=abc")
        once.error("no-scanner", "late", null)
        assertEquals(listOf("error no-scanner"), answers.got)
        assertTrue(once.answered)
    }

    @Test
    fun aCodeReadIsAnswered() {
        val answers = Answers()
        CodeScanner.Once(answers).success("code")
        assertEquals(listOf("success code"), answers.got)
    }
}
