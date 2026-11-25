import XCTest

final class KeyboardTabTests: XCTestCase {
    func testKeyboardTabOpensAndReopens() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let tab = app.buttons["tab.keyboard"]
        XCTAssertTrue(tab.waitForExistence(timeout: 15))
        for _ in 0..<3 {
            tab.tap()
            XCTAssertTrue(app.staticTexts["Nhập liệu nhanh"].waitForExistence(timeout: 10))
            XCTAssertEqual(app.state, .runningForeground)
            // Materialize lower settings, including the asynchronously loaded count.
            for _ in 0..<5 { app.swipeUp() }
            XCTAssertEqual(app.state, .runningForeground)
            app.buttons["tab.owner"].tap()
            XCTAssertEqual(app.state, .runningForeground)
        }
    }
}
