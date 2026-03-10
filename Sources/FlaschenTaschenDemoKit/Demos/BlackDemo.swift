import Foundation
import os.log

// black - Clears the Flaschen Taschen display
// Ported from black.cc by Carl Gorringe

public struct BlackDemo: Sendable {
    public struct Options: Sendable {
        public var hostname: String?
        public var layer = 0
        public var timeout = 0.0
        public var width = 45
        public var height = 35
        public var xoff = 0
        public var yoff = 0
        public var useBlack = false
        public var useColor = false
        public var color = Color()
        public var clearAll = false

        public init(hostname: String? = nil, layer: Int = 0, timeout: Double = 0.0,
                    width: Int = 45, height: Int = 35, xoff: Int = 0, yoff: Int = 0,
                    useBlack: Bool = false, useColor: Bool = false, color: Color = Color(),
                    clearAll: Bool = false) {
            self.hostname = hostname
            self.layer = layer
            self.timeout = timeout
            self.width = width
            self.height = height
            self.xoff = xoff
            self.yoff = yoff
            self.useBlack = useBlack
            self.useColor = useColor
            self.color = color
            self.clearAll = clearAll
        }
    }

    public static func run(options: Options, canvas: UDPFlaschenTaschen) async {
        let logger = Logger(subsystem: Logging.subsystem, category: "black")
        logger.info("black: geometry=\(options.width, privacy: .public)x\(options.height, privacy: .public)+\(options.xoff, privacy: .public)+\(options.yoff, privacy: .public) layer=\(options.layer, privacy: .public) clearAll=\(options.clearAll, privacy: .public)")

        // Fill with color, black, or clear
        if options.useColor {
            canvas.fill(color: options.color)
        } else if options.useBlack {
            canvas.fill(color: Color(r: 1, g: 1, b: 1))
        } else {
            canvas.clear()
        }

        // Use AnimationLoop for consistent timeout handling (1 second per frame)
        let loop = AnimationLoop(timeout: options.timeout, delay: 1000)

        // Capture immutable copies for the async closure
        let clearAll = options.clearAll
        let xoff = options.xoff
        let yoff = options.yoff
        let layer = options.layer

        await loop.run { @Sendable _ in
            if clearAll {
                // Clear all layers
                for layer in 0...15 {
                    canvas.setOffset(x: xoff, y: yoff, z: layer)
                    canvas.send()
                }
            } else {
                // Clear single layer
                canvas.setOffset(x: xoff, y: yoff, z: layer)
                canvas.send()
            }
        }
    }
}
