//
//  glosc_catUITests.swift
//  glosc-catUITests
//
//  Created by XiaoM on 2026/3/21.
//

import XCTest

final class glosc_catUITests: XCTestCase {

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("UITestResetLanguageOverride")
        return app
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testMainFlowsAreVisible() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.staticTexts["说猫语"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["mode.catToHuman"].exists)
        XCTAssertTrue(app.buttons["mode.humanToCat"].exists)
        XCTAssertTrue(app.buttons["record.toggle"].exists)
        XCTAssertTrue(app.staticTexts["内置猫叫样本"].exists)

        app.buttons["mode.humanToCat"].tap()

        XCTAssertTrue(app.buttons["generate.catPhrase"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["speechToText.toggle"].exists)
        XCTAssertTrue(app.textFields["textInput.human"].exists || app.otherElements["textInput.human"].exists)
    }

    @MainActor
    func testLanguageSelectorSwitchesHeroTitle() throws {
        let app = makeApp()
        app.launch()

        let title = app.staticTexts["screen.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertTrue(["说猫语", "Glosc Cat"].contains(title.label))

        app.buttons["language.selector"].tap()
        app.buttons["language.selector.option.zh-Hans"].tap()

        XCTAssertEqual(title.label, "说猫语")

        app.buttons["language.selector"].tap()
        app.buttons["language.selector.option.en"].tap()

        XCTAssertEqual(title.label, "Glosc Cat")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeApp().launch()
        }
    }
}
