import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "lines")

@main
struct Demo {
    static func main() async {
        let args = CommandLine.arguments
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var standardOptions = StandardOptions()
        let firstNonOption = parseStandardOptions(args, into: &standardOptions)

        guard firstNonOption < args.count else {
            print("Usage: lines [options] {one|two|four}")
            return
        }

        let drawMode = args[firstNonOption]
        var drawNum = 1
        if drawMode.hasPrefix("one") {
            drawNum = 1
        } else if drawMode.hasPrefix("two") {
            drawNum = 2
        } else if drawMode.hasPrefix("four") {
            drawNum = 4
        } else {
            print("Usage: lines [options] {one|two|four}")
            return
        }

        let socket = openFlaschenTaschenSocket(hostname: standardOptions.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: standardOptions.width, height: standardOptions.height)

        let options = LinesDemo.Options(standardOptions: standardOptions, drawNum: drawNum)
        await LinesDemo.run(options: options, canvas: canvas)
    }
}
