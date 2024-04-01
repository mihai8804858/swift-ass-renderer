import SwiftUI
import AVKit
import SwiftAssRenderer

struct ContentView: View {
    private enum PlayerKind: CaseIterable {
        case videoPlayer
        #if !os(macOS)
        case playerLayer
        case playerViewController
        #endif
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
                VideoPlayerView(subtitleURL: subtitles[selectedLanguage]!, fontProvider: selectedShaper)
            #if !os(macOS)
            case .playerLayer:
                PlayerLayerView(subtitleURL: subtitles[selectedLanguage]!, fontProvider: selectedShaper)
            case .playerViewController:
                PlayerView(subtitleURL: subtitles[selectedLanguage]!, fontProvider: selectedShaper)
            #endif
            }
        }.padding()
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
                #if !os(macOS)
                case .playerLayer: Text("Player Layer")
                case .playerViewController: Text("Player View Controller")
                #endif
                }
            }
        }.pickerStyle(.menu)
    }
}
