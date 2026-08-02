//
//  BoggleUITests.swift
//  BoggleUITests
//
//  Created by Jacob Anderson on 11/3/23.
//

import XCTest

final class BoggleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGameScreenExposesCoreControls() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Boggle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["newRoundButton"].exists)
        XCTAssertTrue(app.buttons["gameSettingsButton"].exists)
        XCTAssertTrue(app.textFields["wordInput"].exists)
        XCTAssertTrue(app.buttons["boardTile_0_0"].exists)
    }

    func testInvalidTypedWordShowsInlineFeedback() throws {
        let app = XCUIApplication()
        app.launch()

        let wordInput = app.textFields["wordInput"]
        XCTAssertTrue(wordInput.waitForExistence(timeout: 5))
        wordInput.tap()
        wordInput.typeText("ZZZZZZ")
        app.buttons["submitWordButton"].tap()

        let message = app.descendants(matching: .any)["submissionMessage"]
        XCTAssertTrue(message.waitForExistence(timeout: 2))
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
