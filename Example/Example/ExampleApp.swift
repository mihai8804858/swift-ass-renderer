import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
