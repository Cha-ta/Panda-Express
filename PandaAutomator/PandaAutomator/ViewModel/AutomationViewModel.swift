import Foundation
import Combine

@MainActor
class AutomationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var email: String {
        didSet {
            UserDefaults.standard.set(email, forKey: "savedEmail")
        }
    }

    @Published var surveyCode: String = ""
    @Published var isRunning: Bool = false
    @Published var showLogs: Bool = false
    @Published var logMessages: [String] = []
    @Published var status: AutomationStatus = .idle

    // MARK: - Computed Properties

    /// Strips dashes from surveyCode for internal use.
    var cleanCode: String {
        surveyCode.replacingOccurrences(of: "-", with: "")
    }

    /// True when code is exactly 24 alphanumeric chars and email has "@" and ".".
    var isValid: Bool {
        cleanCode.count == 24 && email.contains("@") && email.contains(".")
    }

    // MARK: - Private

    private let engine = AutomationEngine()

    // MARK: - Init

    init() {
        self.email = UserDefaults.standard.string(forKey: "savedEmail") ?? ""
    }

    // MARK: - Public Methods

    func setupEngine() {
        engine.setup()
        engine.onLog = { [weak self] message in
            self?.appendLog(message)
        }
    }

    func startAutomation() {
        guard isValid else { return }
        isRunning = true
        status = .running
        engine.run(code: cleanCode, email: email)
    }

    func appendLog(_ message: String) {
        logMessages.append(message)
    }

    // MARK: - FORM-01: Code Dash Formatting

    /// Strips dashes, keeps first 24 alphanumeric chars uppercased, reinserts a dash every 4 chars.
    func formatCodeWithDashes(_ input: String) -> String {
        // Strip dashes and non-alphanumeric, uppercase, cap at 24
        let clean = input
            .replacingOccurrences(of: "-", with: "")
            .filter { $0.isLetter || $0.isNumber }
            .uppercased()
        let capped = String(clean.prefix(24))

        // Reinsert dashes every 4 chars
        var result = ""
        for (i, char) in capped.enumerated() {
            if i > 0 && i % 4 == 0 {
                result.append("-")
            }
            result.append(char)
        }
        return result
    }
}
