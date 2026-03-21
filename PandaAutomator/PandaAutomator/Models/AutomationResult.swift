/// Typed result from the automation engine's run() method.
/// Replaces log-string parsing for status determination.
enum AutomationResult: Equatable {
    /// Finish/thank-you page detected — survey completed successfully.
    case success
    /// Something went wrong during automation, with description.
    case error(String)
    /// Safety cap hit without detecting finish page.
    case maxPagesReached
}
