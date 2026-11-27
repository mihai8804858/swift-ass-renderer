import Foundation
import QuartzCore
import Testing
import SnapshotTesting
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

func platformName() -> String {
    #if targetEnvironment(macCatalyst)
    "maccatalyst"
    #elseif os(iOS)
    "ios"
    #elseif os(tvOS)
    "tvos"
    #elseif os(macOS)
    "macos"
    #elseif os(visionOS)
    "visionos"
    #endif
}

#if os(macOS)
extension Snapshotting where Value == CALayer, Format == NSImage {
    /// Renders the layer into an sRGB bitmap at a fixed scale. The built-in `.image` strategy draws
    /// with `NSImage.lockFocus()`, which uses the main screen's backing scale and color profile, so
    /// its output depends on the display of the machine that runs the tests (CI runners have
    /// non-Retina virtual displays).
    static func image(scale: CGFloat, precision: Float = 1, perceptualPrecision: Float = 1) -> Snapshotting {
        SimplySnapshotting.image(precision: precision, perceptualPrecision: perceptualPrecision).pullback { layer in
            let size = layer.bounds.size
            let context = CGContext(
                data: nil,
                width: Int((size.width * scale).rounded()),
                height: Int((size.height * scale).rounded()),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.scaleBy(x: scale, y: scale)
            layer.setNeedsLayout()
            layer.layoutIfNeeded()
            layer.render(in: context)
            return NSImage(cgImage: context.makeImage()!, size: size)
        }
    }
}
#endif

/// Layer snapshots that don't depend on the screen the tests run on. Mac destinations would
/// otherwise render at the main screen's scale (and, on macOS, in its color profile), while
/// simulators always have the device's fixed scale.
var layerImage: Snapshotting<CALayer, PlatformImage> {
    #if os(macOS)
    .image(scale: 2)
    #elseif targetEnvironment(macCatalyst)
    .image(traits: UITraitCollection(displayScale: 2))
    #else
    .image
    #endif
}

#if os(macOS)
typealias PlatformImage = NSImage
#else
typealias PlatformImage = UIImage
#endif

func snapshotsDirectory(file: StaticString = #filePath, pathComponents: String...) -> URL {
    let fileURL = URL(fileURLWithPath: "\(file)", isDirectory: false)
    let fileName = fileURL.deletingPathExtension().lastPathComponent
    let snapshotsDirectory = fileURL
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(fileName)

    return pathComponents.reduce(snapshotsDirectory) { $0.appendingPathComponent($1) }
}

func assertSnapshot<Value, Format>(
    of value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, Format>,
    named name: String? = nil,
    snapshotDirectory: URL? = nil,
    record recording: Bool = false,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    let failure = verifySnapshot(
        of: try value(),
        as: snapshotting,
        named: name,
        record: recording,
        snapshotDirectory: snapshotDirectory?.path,
        fileID: fileID,
        file: filePath,
        testName: testName,
        line: line,
        column: column
    )
    guard let message = failure else { return }
    Issue.record(
        Comment(rawValue: message),
        sourceLocation: SourceLocation(
            fileID: "\(fileID)",
            filePath: "\(filePath)",
            line: Int(line),
            column: Int(column)
        )
    )
}
