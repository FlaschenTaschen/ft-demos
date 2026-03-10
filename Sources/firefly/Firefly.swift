import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "firefly")

@main
struct Demo {
    static func main() async {
        let args = CommandLine.arguments
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var standardOptions = StandardOptions()
        _ = parseStandardOptions(args, into: &standardOptions)

        var patternName: String? = nil
        var numLights = 5
        var patternSwitchSeconds = 15

        // Parse custom firefly options
        var i = 1
        while i < args.count {
            let arg = args[i]
            guard arg.hasPrefix("-") else { i += 1; continue }

            let optChar = String(arg.dropFirst())
            switch optChar {
            case "p":
                i += 1
                if i < args.count {
                    patternName = args[i]
                }
            case "n":
                i += 1
                if i < args.count, let n = Int(args[i]), n >= 1 && n <= 25 {
                    numLights = n
                }
            case "s":
                i += 1
                if i < args.count, let s = Int(args[i]), s >= 1 {
                    patternSwitchSeconds = s
                }
            default:
                break
            }
            i += 1
        }

        let socket = openFlaschenTaschenSocket(hostname: standardOptions.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: standardOptions.width, height: standardOptions.height)

        let options = FireflyDemo.Options(
            standardOptions: standardOptions,
            patternName: patternName,
            numLights: numLights,
            patternSwitchSeconds: patternSwitchSeconds
        )

        await FireflyDemo.run(options: options, canvas: canvas)
    }
}
