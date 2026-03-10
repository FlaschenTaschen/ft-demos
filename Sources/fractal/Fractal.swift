import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "fractal")

@main
struct Demo {
    static func main() async {
        let args = CommandLine.arguments
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var standardOptions = StandardOptions()
        let firstNonOption = parseStandardOptions(args, into: &standardOptions)

        guard firstNonOption == args.count else {
            return
        }

        let socket = openFlaschenTaschenSocket(hostname: standardOptions.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: standardOptions.width, height: standardOptions.height)

        let options = FractalDemo.Options(standardOptions: standardOptions)
        await FractalDemo.run(options: options, canvas: canvas)
    }
}
