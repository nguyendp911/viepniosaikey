import XCTest

final class KeyboardTabTests: XCTestCase {
    func testCoupleStudioOpens() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launch()
        let tab=app.buttons["tab.couple"]
        XCTAssertTrue(tab.waitForExistence(timeout:15));tab.tap()
        let entry=app.buttons["couple.studio.conversation"]
        XCTAssertTrue(entry.waitForExistence(timeout:10));entry.tap()
        XCTAssertTrue(app.buttons["couple.studio.close"].waitForExistence(timeout:10))
        let input=app.textViews["couple.conversation.input"]
        XCTAssertTrue(input.exists)
        input.tap()
        input.typeText("Em ban")
        let offline=app.buttons["couple.conversation.offline"]
        for _ in 0..<6 {
            if offline.exists && offline.isHittable{break}
            app.swipeUp()
        }
        XCTAssertTrue(offline.exists && offline.isHittable)
        offline.tap()
        XCTAssertEqual(app.state,.runningForeground)
        let lab=app.buttons["Phân tích & dải cảm xúc Signature"]
        for _ in 0..<6 {
            if lab.exists && lab.isHittable{break}
            app.swipeDown()
        }
        XCTAssertTrue(lab.exists && lab.isHittable);lab.tap()
        XCTAssertTrue(app.buttons["Tạo các sắc thái"].waitForExistence(timeout:10))
        app.buttons["Tạo các sắc thái"].tap()
        XCTAssertEqual(app.state,.runningForeground)
        let signatureClose=app.buttons["couple.signature.close"]
        XCTAssertTrue(signatureClose.waitForExistence(timeout:10));signatureClose.tap()
        app.buttons["couple.studio.close"].tap()
        XCTAssertEqual(app.state,.runningForeground)
    }
    func testUnifiedTypingPremiumOpens() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launch()
        let tab=app.buttons["tab.keyboard"]
        XCTAssertTrue(tab.waitForExistence(timeout:15));tab.tap()
        let entry=app.buttons["typingPremium.open"]
        for _ in 0..<8 {
            if entry.exists && entry.isHittable{break}
            app.swipeUp()
        }
        XCTAssertTrue(entry.exists && entry.isHittable)
        XCTAssertFalse(app.buttons["typingPro6.open"].exists)
        XCTAssertFalse(app.buttons["everyday7.open"].exists)
        entry.tap()
        XCTAssertTrue(app.buttons["typingPremium.close"].waitForExistence(timeout:10))
        // Both formerly separate modules are reachable from one root.
        let language=app.buttons["typingPremium.language"]
        XCTAssertTrue(language.waitForExistence(timeout:10));language.tap()
        XCTAssertTrue(app.navigationBars["Gợi ý & chính tả"].waitForExistence(timeout:10))
        XCTAssertTrue(app.switches["Tự thêm dấu tiếng Việt"].exists)
        app.navigationBars.buttons["Typing Premium"].tap()
        let gestures=app.buttons["typingPremium.gestures"]
        XCTAssertTrue(gestures.waitForExistence(timeout:10));gestures.tap()
        XCTAssertTrue(app.navigationBars["Thao tác gõ & cử chỉ"].waitForExistence(timeout:10))
        app.navigationBars.buttons["Typing Premium"].tap()
        let phrases=app.buttons["typingPremium.phrases"]
        for _ in 0..<8 {
            if phrases.exists && phrases.isHittable{break}
            app.swipeUp()
        }
        XCTAssertTrue(phrases.exists && phrases.isHittable);phrases.tap()
        XCTAssertTrue(app.navigationBars["Cụm từ cá nhân"].waitForExistence(timeout:10))
        XCTAssertEqual(app.state,.runningForeground)
    }
    func testKeyboardTabOpensAndReopens() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launch()
        let tab=app.buttons["tab.keyboard"]
        XCTAssertTrue(tab.waitForExistence(timeout:15))
        for _ in 0..<3 {
            tab.tap()
            XCTAssertTrue(app.staticTexts["Nhập liệu nhanh"].waitForExistence(timeout:10))
            XCTAssertEqual(app.state,.runningForeground)
            if app.buttons["typingPremium.open"].exists && app.buttons["typingPremium.open"].isHittable {
                app.buttons["typingPremium.open"].tap()
                XCTAssertTrue(app.buttons["typingPremium.close"].waitForExistence(timeout:10))
                app.buttons["typingPremium.close"].tap()
                XCTAssertEqual(app.state,.runningForeground)
            }
            for _ in 0..<5{app.swipeUp()}
            XCTAssertEqual(app.state,.runningForeground)
            app.buttons["tab.owner"].tap()
            XCTAssertEqual(app.state,.runningForeground)
        }
    }
}
