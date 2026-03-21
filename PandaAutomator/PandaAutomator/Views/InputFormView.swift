import SwiftUI

struct InputFormView: View {
    @ObservedObject var viewModel: AutomationViewModel

    private var surveyCodeBorderColor: Color {
        if viewModel.isRunning { return Color(.systemGray4) }
        if viewModel.surveyCode.isEmpty { return Color.green.opacity(0.6) }
        let clean = viewModel.surveyCode.replacingOccurrences(of: "-", with: "")
        return clean.count == 24 ? Color.green.opacity(0.6) : .red.opacity(0.7)
    }

    private var emailBorderColor: Color {
        if viewModel.isRunning { return Color(.systemGray4) }
        if viewModel.email.isEmpty { return Color.green.opacity(0.6) }
        let valid = viewModel.email.contains("@") && viewModel.email.contains(".")
        return valid ? Color.green.opacity(0.6) : .red.opacity(0.7)
    }

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
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(surveyCodeBorderColor, lineWidth: 1.5)
                )
        }

        Section("Email") {
            TextField("you@example.com", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .disabled(viewModel.isRunning)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(emailBorderColor, lineWidth: 1.5)
                )
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
