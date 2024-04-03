#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI

#if canImport(UIKit)
public typealias PlatformView = UIView
public typealias PlatformViewController = UIViewController
public typealias PlatformViewRepresentable = UIViewRepresentable
public typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
public typealias PlatformImageView = UIImageView
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
public typealias PlatformView = NSView
public typealias PlatformViewController = NSViewController
public typealias PlatformViewRepresentable = NSViewRepresentable
public typealias PlatformViewControllerRepresentable = NSViewControllerRepresentable
public typealias PlatformImageView = NSImageView
public typealias PlatformImage = NSImage
#endif
