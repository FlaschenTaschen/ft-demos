# FlaschenTaschen Swift Demos

A Swift package for creating and running LED matrix display demos for the [Flaschen Taschen](https://github.com/hzeller/flaschen-taschen) open-source display system.

This is a complete port of the original C++ demos, now in Swift with modern async/await concurrency. All demos communicate with the Flaschen Taschen server via UDP using the PPM (Portable Pixmap) image format.

## What is Flaschen Taschen?

Flaschen Taschen is an open-source LED matrix display system. This Swift library communicates with the FT display server via UDP, sending image data in PPM format. The display runs on a network server (default: `localhost:1337`) that accepts UDP packets containing:

1. **PPM Header**: `P6\n<width> <height>\n255\n` (ASCII text)
2. **Pixel Data**: RGB bytes (3 bytes per pixel, row-major order)
3. **Positioning Footer**: `\n<xoff> <yoff> <zoff>\n` (for layer and offset control)

---

## Quick Start: Your First Demo

### 1. Create a new demo structure

```
Sources/my-demo/MyDemo.swift        # Entry point with CLI parsing
```

### 2. Write minimal demo code

```swift
import Foundation
import FlaschenTaschenDemoKit
import os.log

nonisolated private let logger = Logger(subsystem: Logging.subsystem, category: "my-demo")

@main
struct Demo {
    static func main() async {
        let args = ArgumentPreprocessor.preprocess(args: CommandLine.arguments)
        let argString = args.count > 1 ? args.dropFirst().joined(separator: " ") : "(none)"
        logger.info("Arguments: \(argString, privacy: .public)")

        // Parse standard CLI options
        var options = StandardOptions()
        let firstNonOption = parseStandardOptions(args, into: &options)

        // Connect to FT display and create canvas
        let socket = openFlaschenTaschenSocket(hostname: options.hostname)
        let canvas = UDPFlaschenTaschen(fileDescriptor: socket,
                                       width: options.width,
                                       height: options.height)

        // Run animation loop with async/await
        let loop = AnimationLoop(timeout: options.timeout, delay: options.delay)
        await loop.run { frameCount in
            // Your frame rendering logic here
            canvas.setPixel(x: 0, y: 0, color: Color(r: 255, g: 0, b: 0))

            // Always set offset and send
            canvas.setOffset(x: options.xoff, y: options.yoff, z: options.layer)
            canvas.send()
        }
    }
}
```

### 3. Build and run

```bash
swift build -c release
./.build/release/my-demo -h localhost
```

---

## Standard Command-Line Options

All demos support these common options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-g WxH+X+Y` | geometry | 45x35+0+0 | Canvas width, height, and screen offsets |
| `-l <layer>` | Int | 1 | Z-layer for layering (0-15) |
| `-t <timeout>` | Double | 86400 | Timeout in seconds (default: 24 hours) |
| `-h <host>` | String | localhost | FT display hostname or IP |
| `-d <delay>` | Int | 50 | Frame delay in milliseconds |

**Example**:
```bash
./my-demo -h 192.168.1.100 -g 45x35+0+0 -l 3 -d 75 -t 10
```

---

## Core Library Features

### Animation Loops

The `AnimationLoop` class manages frame timing with non-blocking async/await. This allows multiple demos to run concurrently on different layers without blocking:

```swift
let loop = AnimationLoop(timeout: options.timeout, delay: options.delay)
await loop.run { frameCount in
    // frameCount auto-increments each iteration
    // Loop automatically checks timeout

    // Render frame
    canvas.clear()
    canvas.setPixel(x: 0, y: 0, color: Color(r: 255, g: 0, b: 0))

    // Send to FT display
    canvas.setOffset(x: options.xoff, y: options.yoff, z: options.layer)
    canvas.send()
}
```

**Key properties**:
- `frameCount`: Current frame number (resets at Int.max)
- `elapsed`: Time elapsed in seconds since loop started
- `shouldContinue()`: Returns false when timeout reached

### Color Palettes

Nine predefined 256-color palettes for consistent visual styles:

```swift
var palette = [Color](repeating: Color(), count: 256)
PaletteType.fire.apply(to: &palette)

// Use palette for pixel coloring
for y in 0..<height {
    for x in 0..<width {
        let paletteIndex = Int(pixels[y * width + x])
        canvas.setPixel(x: x, y: y, color: palette[paletteIndex])
    }
}
```

**Available Palettes**:
- `nebula` - Purple → magenta → red → white
- `fire` - Dark blue → red → yellow → white
- `bluegreen` - Blue → cyan → green → yellow
- `rainbow` - Red → yellow → green → blue → magenta
- `colorful` - Red → magenta → cyan → white
- `magma` - Black → purple → red → yellow → white
- `inferno` - Black → purple → orange → yellow → white
- `plasma` - Dark purple → cyan → yellow → white
- `viridis` - Blue → green → yellow

### Drawing Primitives

Geometric shape algorithms for canvas drawing:

```swift
// Lines (Bresenham algorithm)
drawLine(x0: 0, y0: 0, x1: 44, y1: 34,
         color: Color(r: 255, g: 0, b: 0),
         width: 45, height: 35,
         canvas: &canvas)

// Circles (Midpoint circle algorithm)
drawCircle(x0: 22, y0: 17, radius: 10,
           color: 0xFF,
           width: 45, height: 35,
           pixels: &pixels)

// Rectangles
drawBox(x1: 5, y1: 5, x2: 40, y2: 30,
        color: 0xFF, width: 45, height: 35,
        pixels: &pixels)

fillRectangle(x1: 5, y1: 5, x2: 40, y2: 30,
              color: 0xFF, width: 45, height: 35,
              pixels: &pixels)
```

### Image Processing

Pixel buffer effects for motion blur, heat diffusion, and directional flows:

```swift
var pixels = [UInt8](repeating: 0, count: width * height)

// Standard 3x3 blur with decay
blur3(width: 45, height: 35, pixels: &pixels)

// Fire-style blur (orient: 0=upwards, 1=leftwards)
blurFire(width: 45, height: 35, orient: 0, pixels: &pixels)

// Pixel decay for motion effects
decayPixels(pixels: &pixels, decayAmount: 10)
decayPixelsWithThreshold(pixels: &pixels, decayAmount: 5, threshold: 20)
```

### Random Utilities

```swift
// Random RGB color
let color = randomColor()

// Random integer (inclusive range)
let x = randomInt(min: 0, max: 44)

// Random float (inclusive range)
let phase = randomFloat(min: 0.0, max: 1.0)
```

---

## Common Patterns

### Pattern 1: Simple Static Display
For one-time renders with no animation:

```swift
let socket = openFlaschenTaschenSocket(hostname: options.hostname)
let canvas = UDPFlaschenTaschen(fileDescriptor: socket,
                               width: options.width,
                               height: options.height)

canvas.setPixel(x: 0, y: 0, color: Color(r: 255, g: 0, b: 0))
canvas.setPixel(x: 5, y: 5, color: Color(r: 0, g: 0, b: 255))

canvas.setOffset(x: options.xoff, y: options.yoff, z: options.layer)
canvas.send()
```

### Pattern 2: Direct Canvas Drawing
For animations that draw shapes directly:

```swift
let loop = AnimationLoop(timeout: options.timeout, delay: options.delay)
await loop.run { frameCount in
    canvas.clear()

    // Animate a line
    let x1 = (frameCount / 2) % options.width
    let y1 = (frameCount / 3) % options.height
    drawLine(x0: 0, y0: 0, x1: x1, y1: y1,
             color: randomColor(),
             width: options.width, height: options.height,
             canvas: &canvas)

    canvas.setOffset(x: options.xoff, y: options.yoff, z: options.layer)
    canvas.send()
}
```

### Pattern 3: Pixel Buffer with Palette
For effects like blur, plasma, fire that use pixel buffers:

```swift
var pixels = [UInt8](repeating: 0, count: options.width * options.height)
var palette = [Color](repeating: Color(), count: 256)
PaletteType.fire.apply(to: &palette)

let loop = AnimationLoop(timeout: options.timeout, delay: options.delay)
await loop.run { frameCount in
    // Update pixel buffer (add heat, particles, etc.)
    let x = randomInt(min: 0, max: options.width - 1)
    let y = options.height - 1
    pixels[y * options.width + x] = 255

    // Apply effects
    blur3(width: options.width, height: options.height, pixels: &pixels)
    decayPixels(pixels: &pixels, decayAmount: 10)

    // Copy buffer to canvas using palette
    for y in 0..<options.height {
        for x in 0..<options.width {
            let pixelValue = Int(pixels[y * options.width + x])
            canvas.setPixel(x: x, y: y, color: palette[pixelValue])
        }
    }

    canvas.setOffset(x: options.xoff, y: options.yoff, z: options.layer)
    canvas.send()
}
```

### Pattern 4: Palette Cycling
For animations that rotate through color schemes:

```swift
var currentPalette = PaletteType.nebula
var palette = [Color](repeating: Color(), count: 256)
currentPalette.apply(to: &palette)

let loop = AnimationLoop(timeout: options.timeout, delay: options.delay)
await loop.run { frameCount in
    // Change palette every 200 frames
    if frameCount % 200 == 0 {
        currentPalette = nextPaletteType(currentPalette)
        currentPalette.apply(to: &palette)
    }

    // Render using current palette...
    canvas.setOffset(x: options.xoff, y: options.yoff, z: options.layer)
    canvas.send()
}
```

---

## Common Pitfalls and Solutions

### 1. Forgetting to set offset and layer
```swift
// ❌ Wrong - pixels appear at (0, 0) on layer 0
canvas.send()

// ✅ Correct - pixels appear at specified position and layer
canvas.setOffset(x: options.xoff, y: options.yoff, z: options.layer)
canvas.send()
```

### 2. Using blocking sleep instead of async/await
```swift
// ❌ Wrong - blocks event loop
Thread.sleep(forTimeInterval: 0.05)

// ✅ Correct - yields control to event loop
let loop = AnimationLoop(timeout: options.timeout, delay: options.delay)
await loop.run { frameCount in
    canvas.send()
}
```

### 3. Palette index out of bounds
```swift
// ❌ Wrong - crashes if pixel value > 255
let color = palette[Int(pixels[i])]

// ✅ Correct - clamps to 0-255 range
let pixelValue = Int(min(pixels[i], 255))
let color = palette[pixelValue]
```

### 4. Not clearing canvas before drawing
```swift
// ❌ Wrong - shapes accumulate
await loop.run { frameCount in
    drawCircle(...)
    canvas.send()
}

// ✅ Correct - clears before drawing
await loop.run { frameCount in
    canvas.clear()
    drawCircle(...)
    canvas.send()
}
```

### 5. Not handling socket connection failure
```swift
// ❌ Wrong - proceeds with invalid socket
let socket = openFlaschenTaschenSocket(hostname: options.hostname)
let canvas = UDPFlaschenTaschen(fileDescriptor: socket, ...)

// ✅ Correct - verifies socket is valid
let socket = openFlaschenTaschenSocket(hostname: options.hostname)
guard socket >= 0 else {
    print("ERROR: Failed to connect to FT display")
    return
}
let canvas = UDPFlaschenTaschen(fileDescriptor: socket, ...)
```

---

## Building and Testing

### Build
```bash
# Development build
swift build

# Release build (optimized)
swift build -c release
```

### Run
```bash
# Connect to localhost
./.build/release/my-demo

# Connect to specific host
./.build/release/my-demo -h 192.168.1.100

# Use different layer
./.build/release/my-demo -l 5

# Custom geometry
./.build/release/my-demo -g 25x20+10+10

# All options combined
./.build/release/my-demo -h 192.168.1.100 -g 45x35+0+0 -l 3 -d 75 -t 10
```

### Debugging
```bash
# Check for concurrency warnings
swift build 2>&1 | grep -i warning

# View debug output
./.build/release/my-demo 2>&1 | grep -i "debug\|error"

# Test offline (should show connection error)
./.build/release/my-demo -h unreachable -t 2
```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Connection refused" | Check FT server is running at hostname:1337 |
| Pixels appear at wrong position | Verify `-g` geometry and setOffset() call |
| Layer conflicts with other demos | Use different `-l` values (0-15) |
| Animation stutters | Reduce `-d` delay, check CPU load |
| Memory grows over time | Check for buffer allocation in loop (should be outside) |

---

## Concurrency and Async/Await

This project uses **Swift 6 strict concurrency checking** with **async/await and non-blocking Task.sleep()**. This enables multiple demos to run concurrently on different Flaschen Taschen layers without blocking.

**Key points**:
- `Color` is an immutable `Sendable` struct
- Pure functions use `nonisolated` and `Sendable`
- File-scoped loggers are always `nonisolated`
- `UDPFlaschenTaschen` is `@unchecked Sendable` (used synchronously within a task)
- `AnimationLoop` uses non-blocking `Task.sleep(for:)` which yields control to the event loop

```swift
// ✅ Correct - yields control to event loop
let loop = AnimationLoop(timeout: 30, delay: 50)
await loop.run { frameCount in
    canvas.send()
    // Task.sleep(for:) yields control after frame
    // Other tasks can execute while waiting
}
```

---

## PPM Data Format Specification

Flaschen Taschen uses the PPM (Portable Pixmap) binary format for image transmission.

### Format Structure

Each UDP packet contains:

**1. ASCII Header**:
```
P6\n<width> <height>\n255\n
```

**2. Binary Pixel Data**:
- 3 bytes per pixel (R, G, B)
- Row-major order (left-to-right, top-to-bottom)
- No padding

**3. ASCII Footer**:
```
\n<xoffset> <yoffset> <zlayer>\n
```

### Example: 45×35 display
```
P6
45 35
255
[4725 RGB bytes: 45*35*3]
     0     0     1
```

Total size: ~4.8 KB per frame

### UDPFlaschenTaschen builds this automatically

```swift
// Constructor builds PPM structure
let canvas = UDPFlaschenTaschen(fileDescriptor: socket, width: 45, height: 35)

// Set pixels (encoded as RGB triplets in buffer)
canvas.setPixel(x: 0, y: 0, color: Color(r: 255, g: 0, b: 0))

// Update footer with offset/layer
canvas.setOffset(x: 10, y: 5, z: 3)

// Send complete PPM frame as UDP packet
canvas.send()
```

---

## Project Structure

```
Sources/
  FlaschenTaschenDemoKit/                    # Shared library
    AnimationLoop.swift                  # Frame timing
    ColorPalettes.swift                  # 9 color schemes
    DrawingPrimitives.swift              # Lines, circles, boxes
    ImageProcessing.swift                # Blur, decay effects
    Utilities.swift                      # Random, parsing, helpers
    Demos/                               # Library versions of demos
      BlurDemo.swift
      FireflyDemo.swift
      ... (other demos)

  blur/, firefly/, lines/, ...           # CLI entry points for each demo
    Blur.swift
    Firefly.swift
    Lines.swift
    ... (one per demo)
```

---

## Included Demos

20+ demos are included, demonstrating various techniques:

- **blur** - Image processing with blur effects
- **firefly** - Random particles with trails
- **fire** - Fire simulation with upward flow
- **fractal** - Mandelbrot set rendering
- **life** - Conway's Game of Life
- **lines** - Animated line patterns
- **matrix** - Matrix-style falling characters
- **maze** - Maze generation algorithm
- **plasma** - Plasma effect with color cycling
- **sierpinski** - Sierpinski triangle fractal
- And more...

Run any demo:
```bash
./.build/release/blur
./.build/release/fire
./.build/release/life
```

All support the standard `-g`, `-l`, `-t`, `-h`, `-d` options.

---

## Font Resources

### Available Bitmap Fonts

Located in `~/ft/fonts/` - BDF format bitmap fonts:

**Tiny**:
- 4x6.bdf

**Small**:
- 5x5.bdf, 5x7.bdf, 5x8.bdf

**Medium**:
- 6x9.bdf, 6x10.bdf, 6x12.bdf, 6x13.bdf, 6x13B.bdf, 6x13O.bdf

**Larger**:
- 7x13.bdf, 7x13B.bdf, 7x13O.bdf, 7x14.bdf, 7x14B.bdf

**Large**:
- 8x13.bdf, 8x13B.bdf, 8x13O.bdf

**Extra Large**:
- 9x15.bdf, 9x15B.bdf, 9x18.bdf, 9x18B.bdf

**Biggest**:
- 10x20.bdf

**Variants**: B suffix = Bold, O suffix = Oblique

### Vector Font Demo (hack.swift)

The **hack** demo uses a custom vector font with advanced 3D effects:

**Features**:
- Vector font (line segments per character, not bitmap)
- 3D rotation with perspective projection
- Blur/fade effect each frame
- Palette cycling (Nebula, Fire, Bluegreen)
- 45 frames per character rotation
- 8-degree rotation increment per frame
- Line drawing using Bresenham's algorithm

**Character Set**: 36 chars (0-9 + A-Z)

**Format**: Array of line segments per character (x1, y1, x2, y2)

Example:
```bash
./.build/release/hack
```

### Demos Using Fonts

- **hack.swift** - 3D rotating vector letters with palette cycling
- **words.swift** - Text display (bitmap font support)
- **simple-example.swift** - Static text patterns

---

## References

- [Flaschen Taschen GitHub](https://github.com/hzeller/flaschen-taschen)
- [PPM Format Specification](http://netpbm.sourceforge.net/doc/ppm.html)
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency)

---

## Original Source

These demos are ports of the C++ demos found in the original Flaschen Taschen repository. This Swift version maintains full compatibility with the FT display server while adding modern async/await concurrency.
