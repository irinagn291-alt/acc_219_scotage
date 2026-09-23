import XCTest
@testable import Scotage

final class ScotageTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: ScotageApp.self), "ScotageApp")
    }
}
