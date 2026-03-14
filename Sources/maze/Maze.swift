import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "maze")

@main
struct Demo {
    static func main() async {
        let args = ArgumentPreprocessor.preprocess(args: CommandLine.arguments)
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var options = MazeDemo.Options()
        var i = 1

        while i < args.count && args[i].hasPrefix("-") {
            let arg = args[i]
            let option = arg.dropFirst()

            switch option {
            case "?":
                printUsage()
                return

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

            case "c":
                i += 1
                if i < args.count, let color = parseHexColor(args[i]) {
                    options.fgColor = color
                    options.useFGColor = true
                }

            case "v":
                i += 1
                if i < args.count, let color = parseHexColor(args[i]) {
                    options.visitedColor = color
                    options.useVisitedColor = true
                }

            case "b":
                i += 1
                if i < args.count, let color = parseHexColor(args[i]) {
                    options.bgColor = color
                    options.useBGColor = true
                }

            default:
                printUsage()
                return
            }

            i += 1
        }

        // Default hostname from environment or localhost
        if options.hostname == nil {
            options.hostname = ProcessInfo.processInfo.environment["FT_DISPLAY"] ?? "localhost"
        }

        let socket = openFlaschenTaschenSocket(hostname: options.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: options.width, height: options.height)

        await MazeDemo.run(options: options, canvas: canvas)
    }
}

func printUsage() {
    print("Maze (c) 2016 Carl Gorringe (carl.gorringe.org)")
    print("Usage: maze [options]")
    print("Options:")
    print("  -g <W>x<H>[+<X>+<Y>] : Output geometry. (default 45x35+0+0)")
    print("  -l <layer>     : Layer 0-15. (default 2)")
    print("  -t <timeout>   : Timeout exits after given seconds. (default 24hrs)")
    print("  -h <host>      : Flaschen-Taschen display hostname. (FT_DISPLAY)")
    print("  -d <delay>     : Delay between frames in milliseconds. (default 20)")
    print("  -c <RRGGBB>    : Maze color in hex (-c0 = transparent, default white)")
    print("  -v <RRGGBB>    : Visited color in hex (-v0 = transparent, default cycles)")
    print("  -b <RRGGBB>    : Background color in hex (-b0 = #010101, default transparent)")
}
