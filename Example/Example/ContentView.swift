import SwiftUI
import AVKit
import SwiftAssRenderer

enum PlayerKind {
    case videoPlayer
    case playerLayer
    #if canImport(AppKit)
    case playerView
    #else
    case playerViewController
    #endif
}

enum PipelineKind {
    case blend

    @available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *)
    case accelerate
}

enum RenderKind {
    case videoOverlay

    @available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *)
    case videoComposition
}

enum VideoKind {
    case mp4
    case hls
}

enum VideoSource {
    case local
    case remote
}

struct ContentView: View {
    @State private var availableShapers: [FontProvider] = [.fontConfig, .coreText]
    @State private var availablePlayers: [PlayerKind] = {
        #if canImport(AppKit)
        return [.videoPlayer, .playerLayer, .playerView]
        #else
        return [.videoPlayer, .playerLayer, .playerViewController]
        #endif
    }()
    @State private var availablePipelines: [PipelineKind] = {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *) {
            return [.blend, .accelerate]
        } else {
            return [.blend]
        }
    }()
    @State private var availableRenderers: [RenderKind] = {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *) {
            return [.videoOverlay, .videoComposition]
        } else {
            return [.videoOverlay]
        }
    }()
    @State private var availableSources: [VideoSource] = [.local, .remote]
    @State private var availableVideoKinds: [VideoKind] = [.mp4, .hls]
    @State private var availableSubtitles: [String: URL] = [
        "English": Bundle.main.url(forResource: "subtitle-en", withExtension: "ass")!,
        "Arabic": Bundle.main.url(forResource: "subtitle-ar", withExtension: "ass")!,
        "Russian": Bundle.main.url(forResource: "subtitle-ru", withExtension: "ass")!
    ]

    @State private var selectedLanguage = "English"
    @State private var selectedShaper = FontProvider.fontConfig
    @State private var selectedPlayerKind = PlayerKind.videoPlayer
    @State private var selectedPipelineKind = PipelineKind.blend
    @State private var selectedRenderKind = RenderKind.videoOverlay
    @State private var selectedVideoKind = VideoKind.mp4
    @State private var selectedVideoSource = VideoSource.local

    @State private var isPlaying = false
    @State private var unsupportedMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Form {
                languagePickerView
                shaperPickerView
                pipelinePickerView
                playerPickerView
                renderPickerView
                sourcePickerView
                videoKindPickerView
            }
            errorMessage
            playButton
        }.sheet(isPresented: $isPlaying) {
            makePlayer()
        }.onAppear {
            checkCombination()
        }
        #if os(visionOS)
        .onChange(of: selectedRenderKind) { _, _ in checkCombination() }
        .onChange(of: selectedVideoSource) { _, _ in checkCombination() }
        .onChange(of: selectedVideoKind) { _, _ in checkCombination() }
        #else
        .onChange(of: selectedRenderKind) { _ in checkCombination() }
        .onChange(of: selectedVideoSource) { _ in checkCombination() }
        .onChange(of: selectedVideoKind) { _ in checkCombination() }
        #endif
        .padding()
    }

    private var selectedPipeline: ImagePipelineType {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *) {
            switch selectedPipelineKind {
            case .blend: return BlendImagePipeline()
            case .accelerate: return AccelerateImagePipeline()
            }
        } else {
            return BlendImagePipeline()
        }
    }

    private var videoURL: URL {
        switch (selectedVideoSource, selectedVideoKind) {
        case (.local, .mp4):
            Bundle.main.url(forResource: "video", withExtension: "mp4")!
        case (.local, .hls):
            fatalError("Local HLS not supported")
        case (.remote, .mp4):
            URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
        case (.remote, .hls):
            // swiftlint:disable:next line_length
            URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!
        }
    }

    @ViewBuilder
    private var languagePickerView: some View {
        Picker("Subtitle Language", selection: $selectedLanguage) {
            ForEach(Array(availableSubtitles.keys), id: \.self) { language in
                Text(language)
            }
        }.modifier { picker in
            if #available(tvOS 17.0, *) {
                picker.pickerStyle(.menu)
            } else {
                picker.pickerStyle(.automatic)
            }
        }
    }

    @ViewBuilder
    private var pipelinePickerView: some View {
        Picker("Pipeline", selection: $selectedPipelineKind) {
            ForEach(availablePipelines, id: \.self) { pipeline in
                switch pipeline {
                case .blend: Text("Blend")
                case .accelerate: Text("Accelerate")
                }
            }
        }.modifier { picker in
            if #available(tvOS 17.0, *) {
                picker.pickerStyle(.menu)
            } else {
                picker.pickerStyle(.automatic)
            }
        }
    }

    @ViewBuilder
    private var shaperPickerView: some View {
        Picker("Font Shaper", selection: $selectedShaper) {
            ForEach(availableShapers, id: \.self) { shaper in
                switch shaper {
                case .fontConfig: Text("FontConfig")
                case .coreText: Text("CoreText")
                }
            }
        }.modifier { picker in
            if #available(tvOS 17.0, *) {
                picker.pickerStyle(.menu)
            } else {
                picker.pickerStyle(.automatic)
            }
        }
    }

    @ViewBuilder
    private var playerPickerView: some View {
        Picker("Player", selection: $selectedPlayerKind) {
            ForEach(availablePlayers, id: \.self) { player in
                switch player {
                case .videoPlayer: Text("Video Player")
                case .playerLayer: Text("Player Layer")
                #if canImport(AppKit)
                case .playerView: Text("Player View")
                #else
                case .playerViewController: Text("Player View Controller")
                #endif
                }
            }
        }.modifier { picker in
            if #available(tvOS 17.0, *) {
                picker.pickerStyle(.menu)
            } else {
                picker.pickerStyle(.automatic)
            }
        }
    }

    @ViewBuilder
    private var renderPickerView: some View {
        Picker("Render Kind", selection: $selectedRenderKind) {
            ForEach(availableRenderers, id: \.self) { render in
                switch render {
                case .videoOverlay: Text("Overlay")
                case .videoComposition: Text("Composition")
                }
            }
        }.modifier { picker in
            if #available(tvOS 17.0, *) {
                picker.pickerStyle(.menu)
            } else {
                picker.pickerStyle(.automatic)
            }
        }
    }

    @ViewBuilder
    private var sourcePickerView: some View {
        Picker("Video Source", selection: $selectedVideoSource) {
            ForEach(availableSources, id: \.self) { source in
                switch source {
                case .local: Text("Local")
                case .remote: Text("Remote")
                }
            }
        }.modifier { picker in
            if #available(tvOS 17.0, *) {
                picker.pickerStyle(.menu)
            } else {
                picker.pickerStyle(.automatic)
            }
        }
    }

    @ViewBuilder
    private var videoKindPickerView: some View {
        Picker("Video Kind", selection: $selectedVideoKind) {
            ForEach(availableVideoKinds, id: \.self) { kind in
                switch kind {
                case .mp4: Text("MP4")
                case .hls: Text("HLS")
                }
            }
        }.modifier { picker in
            if #available(tvOS 17.0, *) {
                picker.pickerStyle(.menu)
            } else {
                picker.pickerStyle(.automatic)
            }
        }
    }

    @ViewBuilder
    private var errorMessage: some View {
        if let unsupportedMessage {
            Text(unsupportedMessage)
                .foregroundStyle(Color.red)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var playButton: some View {
        Button {
            isPlaying = true
        } label: {
            Label(
                title: { Text("Play") },
                icon: { Image(systemName: "play.circle") }
            )
        }
        .disabled(unsupportedMessage != nil)
        .buttonStyle(.borderedProminent)
    }

    private func makeAsset() -> AVURLAsset {
        AVURLAsset(url: videoURL)
    }

    private func makePlayerItem(asset: AVURLAsset) -> AVPlayerItem {
        AVPlayerItem(asset: asset)
    }

    @ViewBuilder
    private func makePlayer() -> some View {
        let asset = makeAsset()
        let item = makePlayerItem(asset: asset)
        switch selectedPlayerKind {
        case .videoPlayer:
            VideoPlayerView(
                asset: asset,
                playerItem: item,
                subtitleURL: availableSubtitles[selectedLanguage]!,
                fontProvider: selectedShaper,
                pipeline: selectedPipeline,
                renderKind: selectedRenderKind
            )
        case .playerLayer:
            PlayerLayerView(
                asset: asset,
                playerItem: item,
                subtitleURL: availableSubtitles[selectedLanguage]!,
                fontProvider: selectedShaper,
                pipeline: selectedPipeline,
                renderKind: selectedRenderKind
            )
        #if canImport(AppKit)
        case .playerView:
            PlayerView(
                asset: asset,
                playerItem: item,
                subtitleURL: availableSubtitles[selectedLanguage]!,
                fontProvider: selectedShaper,
                pipeline: selectedPipeline,
                renderKind: selectedRenderKind
            )
        #else
        case .playerViewController:
            PlayerView(
                asset: asset,
                playerItem: item,
                subtitleURL: availableSubtitles[selectedLanguage]!,
                fontProvider: selectedShaper,
                pipeline: selectedPipeline,
                renderKind: selectedRenderKind
            )
        #endif
        }
    }

    private func checkCombination() {
        unsupportedMessage = nil
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macCatalyst 16.0, macOS 13.0, *),
            selectedRenderKind == .videoComposition,
            selectedVideoKind == .hls {
            unsupportedMessage = "Video composition rendering not available for HLS"
            return
        }
        if selectedVideoSource == .local, selectedVideoKind == .hls {
            unsupportedMessage = "Local video not available for HLS"
            return
        }
    }
}

private extension View {
    func modifier(@ViewBuilder _ transform: (Self) -> some View) -> some View {
        transform(self)
    }
}
