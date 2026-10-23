import XCTest

@MainActor
final class ScenarioTests: XCTestCase {
    private let app = XCUIApplication()
    private var language: String {
        ProcessInfo.processInfo.environment["UI_TEST_LANGUAGE"] ?? "en"
    }

    private func begin() throws {
        continueAfterFailure = false
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", "en_US"]
        app.launch()
        try tap(app.buttons["onboarding.language.\(language)"])
        capture("01-language")
        try tap(app.buttons["onboarding.continue"])
        capture("02-introduction")
        try tap(app.buttons["onboarding.skip"])
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
    }

    private func tap(_ element: XCUIElement) throws {
        XCTAssertTrue(element.waitForExistence(timeout: 15), "Missing element: \(element)")
        let collection = app.collectionViews.containing(.any, identifier: element.identifier).firstMatch
        let scroll = app.scrollViews.containing(.any, identifier: element.identifier).firstMatch
        for _ in 0 ..< 8 {
            if element.isHittable { break }
            if collection.exists {
                collection.swipeUp()
            } else if scroll.exists {
                scroll.swipeUp()
            } else {
                break
            }
        }
        XCTAssertTrue(element.isHittable, "Element must be visible and tappable: \(element)")
        element.tap()
    }

    private func replaceText(_ identifier: String, with value: String) throws {
        let field = app.textFields[identifier]
        try tap(field)
        let previous = field.value as? String ?? ""
        let placeholder = field.placeholderValue ?? ""
        let deletion = previous == placeholder ? "" : String(
            repeating: XCUIKeyboardKey.delete.rawValue, count: previous.count
        )
        field.typeText(deletion + value)
    }

    private func selectTab(_ index: Int) throws {
        try tap(app.tabBars.buttons.element(boundBy: index))
    }

    private func row(named name: String) -> XCUIElement {
        app.cells.containing(.staticText, identifier: name).firstMatch
    }

    private func editRow(named name: String) throws {
        let cell = row(named: name)
        XCTAssertTrue(cell.waitForExistence(timeout: 15), "Saved record must appear: \(name)")
        cell.swipeLeft()
        try tap(app.buttons["entity.edit"].firstMatch)
    }

    private func capture(_ name: String) {
        // Language crossfades can still render after XCTest reports the app idle.
        Thread.sleep(forTimeInterval: 0.7)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func diagnostics() {
        capture("final-state")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "ui-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        app.terminate()
    }

    override func tearDown() async throws {
        await MainActor.run { diagnostics() }
        try await super.tearDown()
    }

    func testCreateEditCancel() throws {
        try begin()
        let name = "UI regression trip"
        try selectTab(3)
        try tap(app.buttons["entity.add"])
        try replaceText("entity.name", with: name)
        try replaceText("entity.secondary", with: "Kyoto")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        capture("03-create-keyboard")
        try tap(app.buttons["entity.save"])
        XCTAssertTrue(row(named: name).waitForExistence(timeout: 15))
        capture("04-saved")
        try editRow(named: name)
        XCTAssertEqual(app.textFields["entity.name"].value as? String, name)
        XCTAssertEqual(app.textFields["entity.secondary"].value as? String, "Kyoto")
        try replaceText("entity.name", with: "Discard this edit")
        try tap(app.buttons["entity.cancel"])
        XCTAssertTrue(row(named: name).waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["Discard this edit"].exists)
        try editRow(named: name)
        XCTAssertEqual(app.textFields["entity.name"].value as? String, name)
        try tap(app.buttons["entity.cancel"])
        capture("05-cancel-preserved")
        app.terminate()
        app.launch()
        try selectTab(3)
        XCTAssertTrue(row(named: name).waitForExistence(timeout: 15))
    }
}
