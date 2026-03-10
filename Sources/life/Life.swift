import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "life")

@main
struct Demo {
    static func main() async {
        let args = CommandLine.arguments
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var options = LifeDemo.Options()
        var i = 1

        while i < args.count && args[i].hasPrefix("-") {
            let arg = args[i]
            let option = arg.dropFirst()

            switch option {
            case "g":
                i += 1
                if i < args.count, let geom = parseGeometry(args[i]) {
                    options.width = geom.width
                    options.height = geom.height
                    options.xoff = geom.xoff
                    options.yoff = geom.yoff
                }
            case "l":
                i += 1
                if i < args.count, let layer = Int(args[i]), layer >= 0 && layer < 16 {
                    options.layer = layer
                }
            case "t":
                i += 1
                if i < args.count, let timeout = Double(args[i]) {
                    options.timeout = timeout
                }
            case "h":
                i += 1
                if i < args.count {
                    options.hostname = args[i]
                }
            case "d":
                i += 1
                if i < args.count, let delay = Int(args[i]) {
                    options.delay = max(1, delay)
                }
            default:
                break
            }
            i += 1
        }

        if options.hostname == nil {
            options.hostname = ProcessInfo.processInfo.environment["FT_DISPLAY"] ?? "localhost"
        }

        let socket = openFlaschenTaschenSocket(hostname: options.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: options.width, height: options.height)

        await LifeDemo.run(options: options, canvas: canvas)
    }
}
