import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AutomationViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Panda watermark behind all content
                    Image("pandaEating")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.06)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    VStack(spacing: 0) {
                        // Form area — constrained to top half when logs are visible
                        Form {
                            InputFormView(viewModel: viewModel)
                        }
                        .formStyle(.grouped)
                        .frame(
                            height: viewModel.showLogs
                                ? geometry.size.height * 0.50
                                : nil
                        )

                        // Collapsible log area
                        if viewModel.showLogs {
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 2) {
                                        ForEach(
                                            Array(viewModel.logMessages.enumerated()),
                                            id: \.offset
                                        ) { index, message in
                                            Text(message)
                                                .font(.system(.caption, design: .monospaced))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal, 12)
                                                .id(index)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .background(Color(.systemBackground))
                                .onChange(of: viewModel.logMessages.count) { _, count in
                                    if count > 0 {
                                        withAnimation {
                                            proxy.scrollTo(count - 1, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Panda")
            .tint(.green)
        }
        .tint(.green)
        .onAppear {
            viewModel.setupEngine()
        }
    }
}
