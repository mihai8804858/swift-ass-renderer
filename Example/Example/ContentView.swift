import SwiftUI
import AVKit
import SwiftAssRenderer

struct ContentView: View {
    private enum PlayerKind: CaseIterable {
        case videoPlayer
        case playerLayer
        #if os(macOS)
        case playerView
        #else
        case playerViewController
        #endif
    }

    private enum PipelineKind: CaseIterable {
        case blend
        case accelerate
    }

    private let shapers: [FontProvider] = [.fontConfig, .coreText]
    private let subtitles: [String: URL] = [
        "English": Bundle.main.url(forResource: "subtitle-en", withExtension: "ass")!,
        "Arabic": Bundle.main.url(forResource: "subtitle-ar", withExtension: "ass")!,
        "Russian": Bundle.main.url(forResource: "subtitle-ru", withExtension: "ass")!
    ]

    @State private var selectedLanguage = "English"
    @State private var selectedShaper = FontProvider.fontConfig
    @State private var selectedPlayerKind = PlayerKind.videoPlayer
    @State private var selectedPipelineKind = PipelineKind.blend
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 24) {
            Grid(horizontalSpacing: 24) {
                GridRow {
                    Text("Language")
                        .gridColumnAlignment(.trailing)
                    languagePickerView
                        .gridColumnAlignment(.leading)
                }
                GridRow {
                    Text("Shaper")
                        .gridColumnAlignment(.trailing)
                    shaperPickerView
                        .gridColumnAlignment(.leading)
                }
                GridRow {
                    Text("Pipeline")
                        .gridColumnAlignment(.trailing)
                    pipelinePickerView
                        .gridColumnAlignment(.leading)
                }
                GridRow {
                    Text("Player")
                        .gridColumnAlignment(.trailing)
                    playerPickerView
                        .gridColumnAlignment(.leading)
                }
            }
            Button {
                isPlaying = true
            } label: {
                Label(
                    title: { Text("Play") },
                    icon: { Image(systemName: "play.circle") }
                )
            }
        }.sheet(isPresented: $isPlaying) {
            switch selectedPlayerKind {
            case .videoPlayer:
                VideoPlayerView(
                    subtitleURL: subtitles[selectedLanguage]!,
                    fontProvider: selectedShaper,
                    pipeline: selectedPipeline
                )
            case .playerLayer:
                PlayerLayerView(
                    subtitleURL: subtitles[selectedLanguage]!,
                    fontProvider: selectedShaper,
                    pipeline: selectedPipeline
                )
            #if os(macOS)
            case .playerView:
                PlayerView(
                    subtitleURL: subtitles[selectedLanguage]!,
                    fontProvider: selectedShaper,
                    pipeline: selectedPipeline
                )
            #else
            case .playerViewController:
                PlayerView(
                    subtitleURL: subtitles[selectedLanguage]!,
                    fontProvider: selectedShaper,
                    pipeline: selectedPipeline
                )
            #endif
            }
        }.padding()
    }

    private var selectedPipeline: ImagePipelineType {
        switch selectedPipelineKind {
        case .blend: BlendImagePipeline()
        case .accelerate: AccelerateImagePipeline()
        }
    }

    @ViewBuilder
    private var languagePickerView: some View {
        Picker("Subtitle Language", selection: $selectedLanguage) {
            ForEach(Array(subtitles.keys), id: \.self) { language in
                Text(language)
            }
        }.pickerStyle(.menu)
    }

    @ViewBuilder
    private var pipelinePickerView: some View {
        Picker("Pipeline", selection: $selectedPipelineKind) {
            ForEach(PipelineKind.allCases, id: \.self) { pipeline in
                switch pipeline {
                case .blend: Text("Blend")
                case .accelerate: Text("Accelerate")
                }
            }
        }.pickerStyle(.menu)
    }

    @ViewBuilder
    private var shaperPickerView: some View {
        Picker("Font Shaper", selection: $selectedShaper) {
            ForEach(shapers, id: \.self) { shaper in
                switch shaper {
                case .fontConfig: Text("FontConfig")
                case .coreText: Text("CoreText")
                }
            }
        }.pickerStyle(.menu)
    }

    @ViewBuilder
    private var playerPickerView: some View {
        Picker("Player", selection: $selectedPlayerKind) {
            ForEach(PlayerKind.allCases, id: \.self) { player in
                switch player {
                case .videoPlayer: Text("Video Player")
                case .playerLayer: Text("Player Layer")
                #if os(macOS)
                case .playerView: Text("Player View")
                #else
                case .playerViewController: Text("Player View Controller")
                #endif
                }
            }
        }.pickerStyle(.menu)
    }
}
