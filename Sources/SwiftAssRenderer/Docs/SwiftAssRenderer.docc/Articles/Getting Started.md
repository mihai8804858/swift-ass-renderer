# Getting Started

## Overlay Integration

* Define your fonts configuration

```swift
let fontsConfig = FontConfig(
  fontsPath: <PATH_TO_FONTS_DIR>, 
  defaultFontName: <DEFAULT_FONT>
)
```

* Create an instance of renderer

```swift
let renderer = AssSubtitlesRenderer(fontConfig: fontsConfig)
```

* Create an instance of renderer view

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

* Attach the `AVPlayer` to renderer view

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

* Load the subtitles track

    * Local
    ```swift
    let content = try String(contentsOfFile: ...)
    renderer.loadTrack(content: content)
    ```

    * Remote
    ```swift
    let url = ...
    renderer.loadTrack(url: url)
    ```

* Free track when done

```swift
renderer.freeTrack()
```

## Composition Integration

> Important: This rendering method does not support HLS streams.

* Define your fonts configuration

```swift
let fontsConfig = FontConfig(
  fontsPath: <PATH_TO_FONTS_DIR>, 
  defaultFontName: <DEFAULT_FONT>
)
```

* Create an instance of renderer

```swift
let renderer = AssSubtitlesRenderer(fontConfig: fontsConfig)
```

* Attach the renderer to `AVPlayerItem` and `AVAsset`

```swift
struct ContentView: View {
  let asset = AVURLAsset(...)
  let playerItem = AVPlayerItem(...)
  let player = AVPlayer(...)
  let renderer = AssSubtitlesRenderer(...)

  var body: some View {
    VideoPlayer(player: player).onAppear {
      renderer.attach(to: playerItem, asset: asset)
    }
  }
}
```

* Load the subtitles track

    * Local
    ```swift
    let content = try String(contentsOfFile: ...)
    renderer.loadTrack(content: content)
    ```

    * Remote
    ```swift
    let url = ...
    renderer.loadTrack(url: url)
    ```

* Free track when done

```swift
renderer.freeTrack()
```
