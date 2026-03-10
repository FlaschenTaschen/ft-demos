import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "black")

@main
struct Demo {
    static func main() async {
        let args = CommandLine.arguments
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var options = BlackDemo.Options()
        var i = 1

        while i < args.count {
            let arg = args[i]

            if arg.hasPrefix("-") {
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
                case "b":
                    options.useBlack = true
                case "c":
                    i += 1
                    if i < args.count, let color = parseHexColor(args[i]) {
                        options.color = color
                        options.useColor = true
                    }
                default:
                    printUsage()
                    return
                }
            } else if arg == "all" {
                options.clearAll = true
            }

            i += 1
        }

        let socket = openFlaschenTaschenSocket(hostname: options.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: options.width, height: options.height)

        await BlackDemo.run(options: options, canvas: canvas)
    }
}

func printUsage() {
    print("Black (c) 2016 Carl Gorringe (carl.gorringe.org)")
    print("Usage: black [options] [all]")
    print("Options:")
    print("  -g <W>x<H>[+<X>+<Y>] : Output geometry. (default 45x35+0+0)")
    print("  -l <layer>     : Layer 0-15. (default 0)")
    print("  -t <timeout>   : Timeout exits after given seconds. (default now)")
    print("  -h <host>      : Flaschen-Taschen display hostname. (FT_DISPLAY)")
    print("  -b             : Black out with color (1,1,1)")
    print("  -c <RRGGBB>    : Fill with color as hex")
    print("  all            : Clear ALL layers")
}
