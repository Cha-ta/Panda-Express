import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AutomationViewModel()

    var body: some View {
        NavigationStack {
            Form {
                InputFormView(viewModel: viewModel)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background {
                Image("pandaEating")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.18)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .safeAreaInset(edge: .bottom) {
                logArea
            }
            .navigationTitle("Panda")
            .tint(.green)
        }
        .tint(.green)
        .onAppear {
            viewModel.setupEngine()
        }
    }

    @ViewBuilder
    private var logArea: some View {
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
                                .padding(.horizontal, 8)
                                .id(index)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(height: 160)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .onChange(of: viewModel.logMessages.count) { count in
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
