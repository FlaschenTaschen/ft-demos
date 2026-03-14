import Foundation
import FlaschenTaschenClientKit
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "blur")

@main
struct Demo {
    static func main() async {
        let args = ArgumentPreprocessor.preprocess(args: CommandLine.arguments)
        if args.count > 1 {
            logger.info("Arguments: \(args.dropFirst().joined(separator: " "), privacy: .public)")
        }

        var standardOptions = StandardOptions()
        var palette = -1
        var demo = BlurDemoType.bolt
        var orient = 0

        var i = 1
        while i < args.count && args[i].hasPrefix("-") {
            let arg = args[i]
            let option = arg.dropFirst()

            switch option {
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
                if i < args.count, let p = Int(args[i]), p >= 1 && p <= 8 {
                    palette = p
                }
            case "o":
                i += 1
                if i < args.count, let o = Int(args[i]) {
                    orient = o
                }
            default:
                return
            }
            i += 1
        }

        while i < args.count {
            switch args[i].lowercased() {
            case "all": demo = .all
            case "bolt": demo = .bolt
            case "boxes": demo = .boxes
            case "circles": demo = .circles
            case "target": demo = .target
            case "fire": demo = .fire
            default: return
            }
            i += 1
        }

        let socket = openFlaschenTaschenSocket(hostname: standardOptions.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: standardOptions.width, height: standardOptions.height)

        let options = BlurDemo.Options(standardOptions: standardOptions, palette: palette, demo: demo, orient: orient)
        await BlurDemo.run(options: options, canvas: canvas)
    }
}
