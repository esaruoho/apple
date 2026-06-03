// dictation-tests.swift — HEADLESS tests for OnDeviceDictation (shared/Dictation.swift).
// Run:  ./shared/test-dictation.sh
//
// These are the executable half of features/dictation-button.feature: the scenarios
// that DON'T need a live microphone or a TCC grant. Init state, the stop()-when-idle
// no-op safety, and the on-device preference flag run here, on any Mac, no GUI, no
// prompts. The mic-path scenarios (authorize → listen → stream text) can't run
// headlessly — they stay graded @built/@untested in the .feature and are a human
// checklist. Honest about which is which; that's the point of the grade.
import Foundation

var failures = 0
func check(_ name: String, _ cond: Bool) {
    if cond { print("  ok  \(name)") } else { print("FAIL  \(name)"); failures += 1 }
}

@main
enum DictationTests {
    static func main() {
        // Scenario: a fresh engine is idle.
        let d = OnDeviceDictation()
        check("fresh engine: isRunning == false", d.isRunning == false)

        // Scenario: on-device recognition is preferred by default (keeps audio local).
        check("prefersOnDevice defaults to true", d.prefersOnDevice == true)

        // Scenario: stop() while idle is a safe no-op and does NOT fire onStateChange.
        // (Calling stop on a never-started engine must not crash or emit a false flip —
        //  the removeTap/endAudio/finish path has to tolerate the empty state.)
        var stateFlips = 0
        d.onStateChange = { _ in stateFlips += 1 }
        d.stop()
        check("stop() while idle keeps isRunning == false", d.isRunning == false)
        check("stop() while idle fires no onStateChange", stateFlips == 0)

        // Scenario: stop() is safe to call repeatedly — twice while idle is still safe.
        d.stop()
        check("stop() twice while idle is still safe", d.isRunning == false && stateFlips == 0)

        if failures == 0 { print("\n✅ ALL DICTATION-ENGINE TESTS PASS") }
        else { print("\n❌ \(failures) DICTATION TEST FAILURE(S)"); exit(1) }
    }
}
