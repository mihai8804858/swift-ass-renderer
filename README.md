
# SwiftAssRenderer

SSA/ASS subtitles renderer based on [`libass`](https://github.com/libass/libass).

[![CI](https://github.com/mihai8804858/swift-ass-renderer/actions/workflows/ci.yml/badge.svg)](https://github.com/mihai8804858/swift-ass-renderer/actions/workflows/ci.yml)


## Installation

You can add `swift-ass-renderer` to an Xcode project by adding it to your project as a package.

> https://github.com/mihai8804858/swift-ass-renderer

If you want to use `swift-ass-renderer` in a [SwiftPM](https://swift.org/package-manager/) project, it's as
simple as adding it to your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/mihai8804858/swift-ass-renderer", from: "1.0.0")
]
```

And then adding the product to any target that needs access to the library:

```swift
.product(name: "SwiftAssRenderer", package: "swift-ass-renderer"),
```

## Documentation

* [Installation](https://mihai8804858.github.io/swift-ass-renderer/documentation/swiftassrenderer)
* [Overview](https://mihai8804858.github.io/swift-ass-renderer/documentation/swiftassrenderer/overview)
* [Integration](https://mihai8804858.github.io/swift-ass-renderer/tutorials/integration-tutorials/)
  * [VideoPlayer Integration](https://mihai8804858.github.io/swift-ass-renderer/tutorials/swiftassrenderer/videoplayer/)
  * [AVPlayerLayer Integration](https://mihai8804858.github.io/swift-ass-renderer/tutorials/swiftassrenderer/avplayerlayer/)
  * [AVPlayerView Integration](https://mihai8804858.github.io/swift-ass-renderer/tutorials/swiftassrenderer/avplayerview/)
  * [AVPlayerViewController Integration](https://mihai8804858.github.io/swift-ass-renderer/tutorials/swiftassrenderer/avplayerviewcontroller/)
* [Advanced](https://mihai8804858.github.io/swift-ass-renderer/tutorials/advanced-tutorials/)
  * [Custom View Integration](https://mihai8804858.github.io/swift-ass-renderer/tutorials/swiftassrenderer/customviewintegration/)
  * [Custom Drawing](https://mihai8804858.github.io/swift-ass-renderer/tutorials/swiftassrenderer/customimagedrawing/)
  * [Custom Processing](https://mihai8804858.github.io/swift-ass-renderer/tutorials/swiftassrenderer/customimageprocessing/)

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
