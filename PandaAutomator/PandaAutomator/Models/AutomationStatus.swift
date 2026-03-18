enum AutomationStatus: Equatable {
    case idle
    case running
    case success
    case error(String)
}
