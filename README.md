
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

## Quick Start

1. Define your fonts configuration

```swift
let fontsConfig = FontConfig(
  fontsPath: <PATH_TO_FONTS_DIR>, 
  defaultFontName: <DEFAULT_FONT>
)
```

* `fontsPath` - URL path to fonts directory

> [!IMPORTANT]
> The fonts should be placed in `<PATH_TO_FONTS_DIR>/fonts` directory.

* `fontsCachePath` - URL path to fonts cache directory

> [!NOTE]
> The library will append `/fonts-cache` to the `fontsCachePath`.
> If no path is provided, application documents directory will be instead.

* `defaultFontName` - Default font (file name) from `<PATH_TO_FONTS_DIR>/fonts` directory

> [!NOTE]
> This font will be used as fallback when specified fonts in tracks are not found in fonts directory.

* `defaultFontFamily` - Default font family

> [!NOTE]
> This font family will be used as fallback when specified font family in tracks is not found in fonts directory.

2. Create an instance of renderer

```swift
let renderer = AssSubtitlesRenderer(fontConfig: fontsConfig)
```

3. Create an instance of renderer view and add it as an overlay on top of the player view

* `SwiftUI`
```swift
struct ContentView: View {
  let player = AVPlayer(...)
  let renderer = AssSubtitlesRenderer(...)

  var body: some View {
    VideoPlayer(player: player) {
      AssSubtitles(renderer: renderer)
    }
  }
}
```
* `UIKit`

```swift
let subtitlesView = AssSubtitlesView(renderer: renderer)
view.insertSubview(subtitlesView, above: playerView)
```
> [!TIP]
> Make sure to center `AssSubtitlesView` with the player, and resize it using the actual aspect ratio of the video playing.
> [`presentationSize`](https://developer.apple.com/documentation/avfoundation/avplayeritem/1388962-presentationsize) and [`AVMakeRect`](https://developer.apple.com/documentation/avfoundation/1390116-avmakerect) helpers can help in defining the size the subtitles view should use. This is necesarry so the canvas the subtitles are rendered on matched the actual video playing.

```swift
let subtitlesCanvas = AVMakeRect(
  aspectRatio: playerItem.presentationSize,
  insideRect: playerView.bounds
)

NSLayoutConstraint.activate([
  subtitlesView.widthAnchor.constraint(equalToConstant: subtitlesCanvas.width),
  subtitlesView.heightAnchor.constraint(equalToConstant: subtitlesCanvas.height),
  subtitlesView.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
  subtitlesView.centerYAnchor.constraint(equalTo: playerView.centerYAnchor)
])
```

4. Load the subtitles track

```swift
let content = ... // load .ass track content (disk or web)
renderer.loadTrack(content: content)
```

5. Periodically update renderer time offset to update the rendered subtitles

```swift
player.addPeriodicTimeObserver(
  forInterval: CMTime(value: 1, timescale: 10),
  queue: .main,
  using: { renderer.setTimeOffset($0.seconds) }
)
```

6. Free track when done

```swift
renderer.freeTrack()
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
