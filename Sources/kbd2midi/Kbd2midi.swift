// kbd2midi - Keyboard to MIDI converter

import Foundation

@main
struct Kbd2midi {
    static func main() {
        let hostname = ArgumentPreprocessor.preprocess(args: CommandLine.arguments).count > 1 ? ArgumentPreprocessor.preprocess(args: CommandLine.arguments)[1] : nil

        print("kbd2midi: Keyboard to MIDI converter")
        print("Usage: kbd2midi [hostname]")
        print("Reads keyboard input and generates MIDI note events")
        // TODO: Read keyboard input and output MIDI events
    }
}
