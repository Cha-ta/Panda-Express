import SwiftUI

struct InputFormView: View {
    @ObservedObject var viewModel: AutomationViewModel

    var body: some View {
        Section("Survey Code") {
            TextField("1234-5678-9012-3456-7890-1234", text: $viewModel.surveyCode)
                .keyboardType(.default)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .disabled(viewModel.isRunning)
                .onChange(of: viewModel.surveyCode) { newValue in
                    let formatted = viewModel.formatCodeWithDashes(newValue)
                    if formatted != newValue {
                        viewModel.surveyCode = formatted
                    }
                }
        }

        Section("Email") {
            TextField("you@example.com", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .disabled(viewModel.isRunning)
        }

        Section {
            if viewModel.isRunning {
                HStack {
                    ProgressView()
                        .padding(.trailing, 4)
                    Text("Running...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button("Run") {
                    viewModel.startAutomation()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.isValid || viewModel.isRunning)
            }

            Toggle("Show Logs", isOn: $viewModel.showLogs)
        }
    }
}
