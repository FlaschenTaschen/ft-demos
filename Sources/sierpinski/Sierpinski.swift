import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "sierpinski")

@main
struct Demo {
    static func main() async {
        let args = CommandLine.arguments
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        var standardOptions = StandardOptions()
        var paletteMode = true
        var fgColor = Color()
        var bgColor = Color(r: 1, g: 1, b: 1)

        let nextArg = parseStandardOptions(args, into: &standardOptions)

        // Parse custom options (-c foreground, -b background)
        var i = nextArg
        while i < args.count {
            let arg = args[i]
            guard arg.hasPrefix("-") else { i += 1; continue }
            let optChar = String(arg.dropFirst())

            switch optChar {
            case "c":
                i += 1
                if i < args.count, let color = parseHexColor(args[i]) {
                    fgColor = color
                    paletteMode = false
                }
            case "b":
                i += 1
                if i < args.count, let color = parseHexColor(args[i]) {
                    bgColor = color
                }
            default:
                break
            }
            i += 1
        }

        let socket = openFlaschenTaschenSocket(hostname: standardOptions.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: standardOptions.width, height: standardOptions.height)
        canvas.clear()

        let options = SierpinskiDemo.Options(standardOptions: standardOptions, paletteMode: paletteMode, fgColor: fgColor, bgColor: bgColor)
        await SierpinskiDemo.run(options: options, canvas: canvas)
    }
}
