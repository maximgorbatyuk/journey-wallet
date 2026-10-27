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
        if app.tabBars.firstMatch.waitForExistence(timeout: 3) {
            return
        }
        try tap(app.buttons["onboarding.language.\(language)"])
        capture("01-language")
        try tap(app.buttons["onboarding.continue"])
        capture("02-introduction")
        try tap(app.buttons["onboarding.skip"])
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
    }

    private func tap(_ element: XCUIElement) throws {
        _ = element.waitForExistence(timeout: 3)
        for _ in 0 ..< 24 {
            if element.exists, element.isHittable { break }
            var container: XCUIElement?
            if element.exists, !element.identifier.isEmpty {
                let collection = app.collectionViews.containing(.any, identifier: element.identifier).firstMatch
                let scroll = app.scrollViews.containing(.any, identifier: element.identifier).firstMatch
                container = [collection, scroll].first(where: { $0.exists })
            }
            if container == nil {
                let containers = app.collectionViews.allElementsBoundByIndex + app.scrollViews.allElementsBoundByIndex
                container = containers.first(where: { $0.isHittable })
            }
            guard let visible = container else { break }
            scrollVisibleArea(visible)
        }
        XCTAssertTrue(element.exists, "Missing element: \(element)")
        XCTAssertTrue(element.isHittable, "Element must be visible and tappable: \(element)")
        element.tap()
    }

    private func scrollVisibleArea(_ container: XCUIElement) {
        var frame = container.frame.intersection(app.frame)
        let keyboard = app.keyboards.firstMatch
        var obstructions = [app.tabBars.firstMatch, keyboard].filter { $0.exists && $0.isHittable }
        let inputAssistant = app.otherElements["SystemInputAssistantView"].firstMatch
        if keyboard.exists, inputAssistant.exists {
            obstructions.append(inputAssistant)
        }
        for obstruction in obstructions where obstruction.frame.minY > frame.minY {
            frame.size.height = min(frame.maxY, obstruction.frame.minY) - frame.minY
        }
        guard frame.height > 40 else { return }
        // An inset drag reaches the owning Form without scrolling its focused TextEditor.
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let dragX = frame.minX + min(30, frame.width * 0.1)
        let start = origin.withOffset(CGVector(dx: dragX, dy: frame.maxY - 20))
        let end = origin.withOffset(CGVector(dx: dragX, dy: frame.minY + 20))
        start.press(forDuration: 0.05, thenDragTo: end)
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
        let name = "UI regression trip \(UUID().uuidString.prefix(6))"
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

    func testNotesLinksAndDocuments() throws {
        try begin()
        let journeyName = "Notes trip \(UUID().uuidString.prefix(6))"
        let title = "Arrival instructions"
        let content = "Use the courtyard entrance and collect the keys at reception."
        let linkTitle = "Courtyard entrance"
        let documentName = "Arrival voucher"

        try selectTab(3)
        try tap(app.buttons["entity.add"])
        try replaceText("entity.name", with: journeyName)
        try replaceText("entity.secondary", with: "Kyoto")
        try tap(app.buttons["entity.save"])
        try selectTab(1)
        try tap(app.buttons["journey.notes"])
        try tap(app.buttons["note.add"])
        try replaceText("note.title", with: title)
        let editor = app.textViews["note.content"]
        try tap(editor)
        editor.typeText(content)

        try tap(app.buttons["note.link.add"])
        try replaceText("note.link.title", with: "Entrance")
        try replaceText("note.link.url", with: "https://www.google.com/maps/search/?api=1&query=Kyoto")
        try tap(app.buttons["note.link.save"])
        try tap(app.buttons["note.link.edit"].firstMatch)
        try replaceText("note.link.title", with: linkTitle)
        try tap(app.buttons["note.link.save"])

        try importDocumentFromPhotos(named: documentName)
        XCTAssertTrue(app.staticTexts[documentName].waitForExistence(timeout: 15))
        capture("notes-01-editor-attachments")
        try tap(app.buttons["note.save"])
        try tap(app.buttons["note.open"].firstMatch)
        assertNote(title: title, content: content, linkTitle: linkTitle, documentName: documentName)
        capture("notes-02-saved")

        try verifyAttachmentOpening()

        try tap(app.buttons["note.edit"])
        try replaceText("note.title", with: "Discard this instruction edit")
        try tap(app.buttons["note.document.detach"].firstMatch)
        try tap(app.buttons["note.cancel"])
        assertNote(title: title, content: content, linkTitle: linkTitle, documentName: documentName)
        XCTAssertFalse(app.staticTexts["Discard this instruction edit"].exists)
        capture("notes-03-cancel-preserved")

        app.terminate()
        app.launch()
        try selectTab(1)
        try tap(app.buttons["journey.notes"])
        try tap(app.buttons["note.open"].firstMatch)
        assertNote(title: title, content: content, linkTitle: linkTitle, documentName: documentName)
        capture("notes-04-restart-preserved")
    }

    private func verifyAttachmentOpening() throws {
        try tap(app.buttons["note.link.open"].firstMatch)
        let browser = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(browser.wait(for: .runningForeground, timeout: 15))
        app.activate()
        try tap(app.buttons["note.document.open"].firstMatch)
        XCTAssertTrue(app.buttons["document.close"].waitForExistence(timeout: 15))
        capture("notes-02-document-preview")
        try tap(app.buttons["document.close"])
    }

    private func importDocumentFromPhotos(named name: String) throws {
        try tap(app.buttons["note.document.add"])
        try tap(app.buttons["note.document.new"].firstMatch)
        try tap(app.buttons["document.import.photos"])
        try selectImportedPhoto()
        try replaceText("document.name", with: name)
        try tap(app.buttons["document.save"])
    }

    private func selectImportedPhoto() throws {
        let picker = app.scrollViews["photosView_content_scroll_view"]
        let photo = picker.images.matching(identifier: "PXGGridLayout-Info").firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 15))
        // Photos exposes grid items as images without an accessibility hit point.
        photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let navigation = app.navigationBars.matching(NSPredicate(
            format: "identifier == %@ OR identifier == %@", "Photos", "Фото"
        )).firstMatch
        let add = navigation.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@ OR label BEGINSWITH %@ OR label BEGINSWITH %@ OR label BEGINSWITH %@",
            "Done", "Готово", "Add", "Добавить"
        )).firstMatch
        try tap(add)
    }

    private func assertNote(title: String, content: String, linkTitle: String, documentName: String) {
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts[content].exists)
        let link = app.buttons["note.link.open"].firstMatch
        XCTAssertTrue(link.waitForExistence(timeout: 15))
        XCTAssertTrue(link.label.contains(linkTitle))
        let document = app.buttons["note.document.open"].firstMatch
        XCTAssertTrue(document.exists)
        XCTAssertTrue(document.label.contains(documentName))
    }
}
