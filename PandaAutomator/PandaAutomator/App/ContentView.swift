import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AutomationViewModel()

    var body: some View {
        // Placeholder — Plan 02 builds the full UI.
        Text("Panda")
            .onAppear {
                viewModel.setupEngine()
            }
    }
}
