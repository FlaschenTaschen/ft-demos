import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "simple-animation")

@main
struct Demo {
    static func main() async {
        let args = CommandLine.arguments
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var standardOptions = StandardOptions()
        _ = parseStandardOptions(args, into: &standardOptions)

        let socket = openFlaschenTaschenSocket(hostname: standardOptions.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: standardOptions.width, height: standardOptions.height)

        let options = SimpleAnimationDemo.Options(standardOptions: standardOptions, fileDescriptor: socket)
        await SimpleAnimationDemo.run(options: options, canvas: canvas)
    }
}
