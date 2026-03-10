import Foundation
import os.log

// life - Conway's Game of Life cellular automaton
// Ported from life.cc

class LifeGameState: @unchecked Sendable {
    var paletteIndex = 0
    var lastRespawnTime = Date()
}

class GameOfLife: @unchecked Sendable {
    var pixels: [UInt8]
    let width: Int
    let height: Int

    init(width: Int, height: Int, density: Int) {
        self.width = width
        self.height = height
        self.pixels = [UInt8](repeating: 0, count: width * height)

        // Initialize with random cells: 1/density chance to be alive
        for i in 0..<(width * height) {
            pixels[i] = (randomInt(min: 0, max: density - 1) == 0) ? 1 : 0
        }
    }

    func runGeneration() {
        var newPixels = [UInt8](repeating: 0, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                var neighborCount = 0

                // Count neighbors with toroidal wrapping
                for dy in -1...1 {
                    for dx in -1...1 {
                        if dx == 0 && dy == 0 { continue }

                        let ny = (y + dy + height) % height
                        let nx = (x + dx + width) % width

                        if pixels[ny * width + nx] != 0 {
                            neighborCount += 1
                        }
                    }
                }

                let isAlive = pixels[y * width + x] != 0
                let idx = y * width + x

                // Conway's Game of Life rules
                if isAlive {
                    // Live cell with 2-3 neighbors survives
                    newPixels[idx] = (neighborCount == 2 || neighborCount == 3) ? 1 : 0
                } else {
                    // Dead cell with exactly 3 neighbors becomes alive
                    newPixels[idx] = (neighborCount == 3) ? 1 : 0
                }
            }
        }

        pixels = newPixels
    }

    func respawn(density: Int) {
        for i in 0..<(width * height) {
            pixels[i] = (randomInt(min: 0, max: density - 1) == 0) ? 1 : 0
        }
    }
}

public struct LifeDemo: Sendable {
    public struct Options: Sendable {
        public var hostname: String?
        public var layer: Int = 2
        public var timeout: Double = 60 * 60 * 24.0
        public var width: Int = 45
        public var height: Int = 35
        public var xoff: Int = 0
        public var yoff: Int = 0
        public var delay: Int = 200
        public var respawn: Double = 0.0
        public var hasCustomFgColor: Bool = false
        public var fgColor: Color = Color(r: 0, g: 0, b: 0)
        public var hasCustomBgColor: Bool = false
        public var bgColor: Color = Color(r: 0, g: 0, b: 0)
        public var numDots: Int = 6

        public init(hostname: String? = nil, layer: Int = 2, timeout: Double = 60 * 60 * 24.0,
                    width: Int = 45, height: Int = 35, xoff: Int = 0, yoff: Int = 0, delay: Int = 200,
                    respawn: Double = 0.0, hasCustomFgColor: Bool = false, fgColor: Color = Color(r: 0, g: 0, b: 0),
                    hasCustomBgColor: Bool = false, bgColor: Color = Color(r: 0, g: 0, b: 0), numDots: Int = 6) {
            self.hostname = hostname
            self.layer = layer
            self.timeout = timeout
            self.width = width
            self.height = height
            self.xoff = xoff
            self.yoff = yoff
            self.delay = delay
            self.respawn = respawn
            self.hasCustomFgColor = hasCustomFgColor
            self.fgColor = fgColor
            self.hasCustomBgColor = hasCustomBgColor
            self.bgColor = bgColor
            self.numDots = numDots
        }
    }

    public static func run(options: Options, canvas: UDPFlaschenTaschen) async {
        let logger = Logger(subsystem: Logging.subsystem, category: "life")
        logger.info("life: geometry=\(options.width, privacy: .public)x\(options.height, privacy: .public)+\(options.xoff, privacy: .public)+\(options.yoff, privacy: .public) layer=\(options.layer, privacy: .public) delay=\(options.delay, privacy: .public)ms respawn=\(options.respawn, privacy: .public)s")

        let game = GameOfLife(width: options.width, height: options.height, density: options.numDots)
        let palette = createRainbowPalette()
        let state = LifeGameState()

        // Extract immutable options for closure capture
        let width = options.width
        let height = options.height
        let numDots = options.numDots
        let respawn = options.respawn
        let hasCustomFgColor = options.hasCustomFgColor
        let fgColor = options.fgColor
        let hasCustomBgColor = options.hasCustomBgColor
        let bgColor = options.bgColor
        let xoff = options.xoff
        let yoff = options.yoff
        let layer = options.layer

        let loop = AnimationLoop(timeout: options.timeout, delay: options.delay)
        let callback: @Sendable (Int) async -> Void = { _ in
            // Run one generation
            game.runGeneration()

            // Check for respawn
            if respawn > 0 {
                let now = Date()
                if now.timeIntervalSince(state.lastRespawnTime) > respawn {
                    state.lastRespawnTime = now
                    game.respawn(density: numDots)
                }
            }

            // Determine foreground color
            let displayFgColor = hasCustomFgColor ? fgColor : palette[state.paletteIndex]
            let displayBgColor = hasCustomBgColor ? bgColor : Color(r: 0, g: 0, b: 0)

            // Render to canvas
            for y in 0..<height {
                for x in 0..<width {
                    let isAlive = game.pixels[y * width + x] != 0
                    canvas.setPixel(x: x, y: y, color: isAlive ? displayFgColor : displayBgColor)
                }
            }

            canvas.setOffset(x: xoff, y: yoff, z: layer)
            canvas.send()

            // Advance palette color for next frame
            state.paletteIndex += 1
            if state.paletteIndex >= 256 {
                state.paletteIndex = 0
            }
        }
        await loop.run(frameCallback: callback)
    }

    private static func createRainbowPalette() -> [Color] {
        var palette = [Color](repeating: Color(), count: 256)

        // Create 8 color gradients forming a rainbow
        colorGradient(start: 0, end: 31, r1: 255, g1: 0, b1: 255, r2: 0, g2: 0, b2: 255, into: &palette)
        colorGradient(start: 32, end: 63, r1: 0, g1: 0, b1: 255, r2: 0, g2: 255, b2: 255, into: &palette)
        colorGradient(start: 64, end: 95, r1: 0, g1: 255, b1: 255, r2: 0, g2: 255, b2: 0, into: &palette)
        colorGradient(start: 96, end: 127, r1: 0, g1: 255, b1: 0, r2: 127, g2: 255, b2: 0, into: &palette)
        colorGradient(start: 128, end: 159, r1: 127, g1: 255, b1: 0, r2: 255, g2: 255, b2: 0, into: &palette)
        colorGradient(start: 160, end: 191, r1: 255, g1: 255, b1: 0, r2: 255, g2: 127, b2: 0, into: &palette)
        colorGradient(start: 192, end: 223, r1: 255, g1: 127, b1: 0, r2: 255, g2: 0, b2: 0, into: &palette)
        colorGradient(start: 224, end: 255, r1: 255, g1: 0, b1: 0, r2: 255, g2: 0, b2: 255, into: &palette)

        return palette
    }

    private static func colorGradient(start: Int, end: Int, r1: Int, g1: Int, b1: Int, r2: Int, g2: Int, b2: Int, into palette: inout [Color]) {
        let count = end - start
        for i in 0...count {
            let k = Double(i) / Double(count)
            let r = UInt8(Int(Double(r1) + Double(r2 - r1) * k))
            let g = UInt8(Int(Double(g1) + Double(g2 - g1) * k))
            let b = UInt8(Int(Double(b1) + Double(b2 - b1) * k))
            palette[start + i] = Color(r: r, g: g, b: b)
        }
    }
}
