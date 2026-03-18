import XCTest
@testable import PandaAutomator

final class EmailPersistenceTests: XCTestCase {

    private let defaultsKey = "savedEmail"

    override func setUp() {
        super.setUp()
        // Clear before each test
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        super.tearDown()
    }

    @MainActor
    func testEmailPersistsToUserDefaults() {
        let vm = AutomationViewModel()
        vm.email = "persist@example.com"
        let stored = UserDefaults.standard.string(forKey: defaultsKey)
        XCTAssertEqual(stored, "persist@example.com")
    }

    @MainActor
    func testEmailLoadsFromUserDefaultsOnInit() {
        UserDefaults.standard.set("preloaded@example.com", forKey: defaultsKey)
        let vm = AutomationViewModel()
        XCTAssertEqual(vm.email, "preloaded@example.com")
    }
}
