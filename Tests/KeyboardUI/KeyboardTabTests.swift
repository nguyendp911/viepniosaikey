import XCTest

final class KeyboardTabTests: XCTestCase {
    func testEverydaySettingsOpens() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launch()
        let tab=app.buttons["tab.keyboard"]
        XCTAssertTrue(tab.waitForExistence(timeout:15));tab.tap()
        let entry=app.buttons["everyday7.open"]
        for _ in 0..<8 {
            if entry.exists && entry.isHittable{break}
            app.swipeUp()
        }
        XCTAssertTrue(entry.exists && entry.isHittable);entry.tap()
        XCTAssertTrue(app.buttons["everyday7.close"].waitForExistence(timeout:10))
        let phrases=app.buttons["Cụm từ đã học"]
        XCTAssertTrue(phrases.waitForExistence(timeout:10));phrases.tap()
        XCTAssertTrue(app.navigationBars["Cụm từ cá nhân"].waitForExistence(timeout:10))
        XCTAssertEqual(app.state,.runningForeground)
    }
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
            if app.buttons["typingPro6.open"].exists && app.buttons["typingPro6.open"].isHittable {
                app.buttons["typingPro6.open"].tap()
                XCTAssertTrue(app.buttons["typingPro6.close"].waitForExistence(timeout: 10))
                app.buttons["typingPro6.close"].tap()
                XCTAssertEqual(app.state, .runningForeground)
            }
            // Materialize lower settings, including the asynchronously loaded count.
            for _ in 0..<5 { app.swipeUp() }
            XCTAssertEqual(app.state, .runningForeground)
            app.buttons["tab.owner"].tap()
            XCTAssertEqual(app.state, .runningForeground)
        }
    }
}
