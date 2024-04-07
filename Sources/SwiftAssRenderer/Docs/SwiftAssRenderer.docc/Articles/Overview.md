# Overview

## Quick Start

1. Define your fonts configuration

```swift
let fontsConfig = FontConfig(
  fontsPath: <PATH_TO_FONTS_DIR>, 
  defaultFontName: <DEFAULT_FONT>
)
```

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
> Make sure to center `AssSubtitlesView` with the player, and resize it using the actual aspect ratio of the video playing.
> [`presentationSize`](https://developer.apple.com/documentation/avfoundation/avplayeritem/1388962-presentationsize) and [`AVMakeRect`](https://developer.apple.com/documentation/avfoundation/1390116-avmakerect) helpers can help in defining the size the subtitles view should use. This is necessary so the canvas the subtitles are rendered on matched the actual video playing.

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
