// Shared utilities for Flaschen Taschen demos

import Foundation
import os.log

/// Generate a random integer in the range [min, max] inclusive
public nonisolated func randomInt(min: Int, max: Int) -> Int {
    return Int.random(in: min...max)
}

/// Parse geometry string in format "WxH+X+Y" or "WxH"
public nonisolated func parseGeometry(_ geometry: String) -> (width: Int, height: Int, xoff: Int, yoff: Int)? {
    let parts = geometry.split(separator: "x", maxSplits: 1, omittingEmptySubsequences: true)
    guard parts.count >= 2, let width = Int(parts[0]) else { return nil }

    let heightAndOffset = String(parts[1])
    let offsetParts = heightAndOffset.split(separator: "+", omittingEmptySubsequences: true)

    guard let height = Int(offsetParts[0]) else { return nil }

    let xoff = offsetParts.count > 1 ? Int(offsetParts[1]) ?? 0 : 0
    let yoff = offsetParts.count > 2 ? Int(offsetParts[2]) ?? 0 : 0

    return (width, height, xoff, yoff)
}

/// Parse hex color string in format "RRGGBB"
public nonisolated func parseHexColor(_ hex: String) -> Color? {
    let cleanHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard cleanHex.count == 6 else { return nil }

    let scanner = Scanner(string: cleanHex)
    var value: UInt32 = 0
    guard scanner.scanHexInt32(&value) else { return nil }

    let r = UInt8((value >> 16) & 0xFF)
    let g = UInt8((value >> 8) & 0xFF)
    let b = UInt8(value & 0xFF)

    return Color(r: r, g: g, b: b)
}

/// Create a sprite from a text pattern (# = colored pixel, space = black)
public nonisolated func createSpriteFromPattern(_ fileDescriptor: Int32, pattern: [String], color: Color) -> UDPFlaschenTaschen {
    let width = pattern.map { $0.count }.max() ?? 0
    let height = pattern.count

    let canvas = UDPFlaschenTaschen(fileDescriptor: fileDescriptor, width: width + 2, height: height + 2)
    canvas.clear()

    for (row, line) in pattern.enumerated() {
        for (col, char) in line.enumerated() {
            if char != " " {
                canvas.setPixel(x: col + 1, y: row + 1, color: color)
            }
        }
    }

    return canvas
}

/// Log command-line arguments for easy copy/paste to original demos
public nonisolated func logArguments(_ logger: Logger, category: String) {
    let args = ArgumentPreprocessor.preprocess(args: CommandLine.arguments)
    let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
    logger.info("Arguments: \(argString, privacy: .public)")
}

// MARK: - Standard Options and Argument Parsing

/// Standard options common to most demos - immutable value type, safe for concurrent use
public nonisolated struct StandardOptions: Sendable {
    public var hostname: String?
    public var layer: Int = 1
    public var timeout: Double = 60 * 60 * 24.0  // 24 hours
    public var width: Int = 45
    public var height: Int = 35
    public var xoff: Int = 0
    public var yoff: Int = 0
    public var delay: Int = 50

    public nonisolated init() {}
}

/// Parse standard command-line options (-g, -l, -t, -h, -d)
/// Returns the index of the first non-option argument
public nonisolated func parseStandardOptions(_ args: [String], into options: inout StandardOptions) -> Int {
    var i = 1
    while i < args.count {
        let arg = args[i]

        guard arg.hasPrefix("-") else { break }

        let optChar = String(arg.dropFirst())

        switch optChar {
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

    return i
}

// MARK: - Random Utilities

/// Generate a random color with full RGB range
public nonisolated func randomColor() -> Color {
    return Color(
        r: UInt8.random(in: 0...255),
        g: UInt8.random(in: 0...255),
        b: UInt8.random(in: 0...255)
    )
}

/// Generate a random float in the given range
public nonisolated func randomFloat(min: Float, max: Float) -> Float {
    return Float.random(in: min...max)
}
