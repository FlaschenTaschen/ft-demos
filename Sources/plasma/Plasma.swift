import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "plasma")

@main
struct Demo {
    static func main() async {
        let args = CommandLine.arguments
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var standardOptions = StandardOptions()
        var paletteIndex = 0

        var i = 1
        while i < args.count && args[i].hasPrefix("-") {
            let arg = args[i]
            let optChar = String(arg.dropFirst())

            switch optChar {
            case "g":
                i += 1
                if i < args.count, let geom = parseGeometry(args[i]) {
                    standardOptions.width = geom.width
                    standardOptions.height = geom.height
                    standardOptions.xoff = geom.xoff
                    standardOptions.yoff = geom.yoff
                }

            case "l":
                i += 1
                if i < args.count, let layer = Int(args[i]), layer >= 0 && layer < 16 {
                    standardOptions.layer = layer
                }

            case "t":
                i += 1
                if i < args.count, let timeout = Double(args[i]) {
                    standardOptions.timeout = timeout
                }

            case "h":
                i += 1
                if i < args.count {
                    standardOptions.hostname = args[i]
                }

            case "d":
                i += 1
                if i < args.count, let delay = Int(args[i]) {
                    standardOptions.delay = max(1, delay)
                }

            case "p":
                i += 1
                if i < args.count, let palette = Int(args[i]), palette >= 0 && palette <= 8 {
                    paletteIndex = palette
                }

            default:
                return
            }

            i += 1
        }

        let socket = openFlaschenTaschenSocket(hostname: standardOptions.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: standardOptions.width, height: standardOptions.height)

        let options = PlasmaDemo.Options(standardOptions: standardOptions, paletteIndex: paletteIndex)
        await PlasmaDemo.run(options: options, canvas: canvas)
    }
}
