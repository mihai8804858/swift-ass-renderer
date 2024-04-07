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

3. Create an instance of renderer view

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
let player = AVPlayer(...)
let renderer = AssSubtitlesRenderer(...)
let subtitlesView = AssSubtitlesView(renderer: renderer)
```

4. Attach the `AVPlayer` to renderer view

* `SwiftUI`
```swift
struct ContentView: View {
  let player = AVPlayer(...)
  let renderer = AssSubtitlesRenderer(...)

  var body: some View {
    VideoPlayer(player: player) {
      AssSubtitles(renderer: renderer)
        .attach(player: player, updateInterval: CMTime(value: 1, timescale: 10))
    }
  }
}
```

* `UIKit`
```swift
subtitlesView.attach(
    to: avPlayerViewController,
    updateInterval: CMTime(value: 1, timescale: 10),
    storeCancellable: { [weak self] in self?.cancellables.insert($0) }
)
```

5. Load the subtitles track

```swift
let content = ... // load .ass track content (disk or web)
renderer.loadTrack(content: content)
```

6. Free track when done

```swift
renderer.freeTrack()
```
