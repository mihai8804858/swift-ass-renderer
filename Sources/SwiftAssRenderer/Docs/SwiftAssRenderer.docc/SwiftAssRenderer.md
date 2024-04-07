# ``SwiftAssRenderer``

SSA/ASS subtitles renderer based on `libass`.

## Installation

You can add `swift-ass-renderer` to an Xcode project by adding it to your project as a package.

```
https://github.com/mihai8804858/swift-ass-renderer
```

If you want to use `swift-ass-renderer` in a [SwiftPM](https://swift.org/package-manager/) project, it's as
simple as adding it to your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/mihai8804858/swift-ass-renderer", from: "1.0.0")
]
```

And then adding the product to any target that needs access to the library:

```swift
.product(name: "SwiftAssRenderer", package: "swift-ass-renderer")
```

## Topics

### Overview

- <doc:Overview>

### Tutorials

- <doc:Integration-Tutorials>
- <doc:Advanced-Tutorials>
