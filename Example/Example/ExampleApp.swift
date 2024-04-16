import SwiftUI
import AVFoundation

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    #if !os(macOS)
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback)
                    } catch {
                        print("Setting category to .playback failed: \(error)")
                    }
                    #endif
                }
                #if os(visionOS)
                .onAppear {
                    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                    scene.requestGeometryUpdate(.Vision(resizingRestrictions: .uniform))
                }
                #endif
        }
        #if os(visionOS)
        .defaultSize(width: 1920, height: 1080)
        #endif
    }
}
