import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "nb-logo")

@main
struct Demo {
    static func main() async {
        let args = ArgumentPreprocessor.preprocess(args: CommandLine.arguments)
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var standardOptions = StandardOptions()
        var logoColor: Color? = nil

        let nextArg = parseStandardOptions(args, into: &standardOptions)

        // Parse custom option (-c logo color)
        var i = nextArg
        while i < args.count {
            let arg = args[i]
            guard arg.hasPrefix("-") else { i += 1; continue }
            let optChar = String(arg.dropFirst())

            switch optChar {
            case "c":
                i += 1
                if i < args.count, let color = parseHexColor(args[i]) {
                    logoColor = color
                }
            default:
                break
            }
            i += 1
        }

        let socket = openFlaschenTaschenSocket(hostname: standardOptions.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: standardOptions.width, height: standardOptions.height)
        canvas.clear()

        let options = NbLogoDemo.Options(standardOptions: standardOptions, logoColor: logoColor)
        await NbLogoDemo.run(options: options, canvas: canvas)
    }
}
