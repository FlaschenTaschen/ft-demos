// midi - Player piano visualization driven by MIDI input

import Foundation

@main
struct Midi {
    static func main() {
        print("midi: Player piano visualization from MIDI input")
        print("Usage: cat /dev/midi | midi [options] {scroll|across|boxes}")
        print("  -g <W>x<H>[+<X>+<Y>]: Output geometry")
        print("  -l <layer>: Layer 0-15")
        print("  -h <host>: Hostname")
        print("  -d <delay>: Delay in ms")
        print("  -c <RRGGBB>: Note color")
        // TODO: Read MIDI input and render notes
    }
}
