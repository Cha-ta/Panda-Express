import SwiftUI

/// Placeholder for the survey input form. Plan 02 implements the full UI.
struct InputFormView: View {
    @ObservedObject var viewModel: AutomationViewModel

    var body: some View {
        Form {
            Section("Survey Code") {
                TextField("1234-5678-9012-3456-7890-1234", text: $viewModel.surveyCode)
                    .keyboardType(.default)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .onChange(of: viewModel.surveyCode) { _, newValue in
                        viewModel.surveyCode = viewModel.formatCodeWithDashes(newValue)
                    }
            }

            Section("Email") {
                TextField("you@example.com", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Section {
                Button("Run") { viewModel.startAutomation() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .frame(maxWidth: .infinity)
                    .disabled(!viewModel.isValid || viewModel.isRunning)

                Toggle("Show logs", isOn: $viewModel.showLogs)
            }
        }
        .formStyle(.grouped)
        .disabled(viewModel.isRunning)
    }
}
