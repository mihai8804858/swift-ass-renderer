#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI

#if canImport(UIKit)
public typealias PlatformView = UIView
public typealias PlatformViewRepresentable = UIViewRepresentable
public typealias PlatformImageView = UIImageView
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
public typealias PlatformView = NSView
public typealias PlatformViewRepresentable = NSViewRepresentable
public typealias PlatformImageView = NSImageView
public typealias PlatformImage = NSImage
#endif
