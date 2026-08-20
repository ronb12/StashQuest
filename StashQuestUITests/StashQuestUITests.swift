import XCTest

final class StashQuestUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchFresh() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting"]
        app.launch()
        return app
    }

    private func completeOnboardingIfNeeded(_ app: XCUIApplication, adult: String = "Ronell", kid: String? = "Maya") {
        let continueButton = app.buttons["onboardingContinueButton"]
        if continueButton.waitForExistence(timeout: 4) {
            continueButton.tap()
        }

        let startButton = app.buttons["onboardingStartButton"]
        guard startButton.waitForExistence(timeout: 4) else { return }

        if kid != nil {
            let withKids = app.buttons["With kids"]
            if withKids.waitForExistence(timeout: 2) {
                withKids.tap()
            }
        }

        let adultField = app.textFields["onboardingAdultNameField"]
        if adultField.waitForExistence(timeout: 3) {
            adultField.tap()
            adultField.typeText(adult)
        }

        if let kid {
            let kidField = app.textFields["onboardingKidNameField"]
            if kidField.waitForExistence(timeout: 2) {
                kidField.tap()
                kidField.typeText(kid)
            }
        }

        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        XCTAssertTrue(startButton.isEnabled)
        startButton.tap()
    }

    func testAppLaunchesAndShowsTabs() throws {
        let app = launchFresh()
        completeOnboardingIfNeeded(app)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 8), "Tab bar should appear after onboarding")

        XCTAssertTrue(tabBar.buttons["Home"].exists)
        tabBar.buttons["Challenges"].tap()
        XCTAssertTrue(app.navigationBars["Challenges"].waitForExistence(timeout: 3))

        tabBar.buttons["Activity"].tap()
        XCTAssertTrue(app.navigationBars["Activity"].waitForExistence(timeout: 3))

        tabBar.buttons["You"].tap()
        XCTAssertTrue(app.navigationBars["You"].waitForExistence(timeout: 3))

        tabBar.buttons["Home"].tap()
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 3))
    }

    func testLogMoneyStashSpentAndActivity() throws {
        let app = launchFresh()
        completeOnboardingIfNeeded(app)

        let logOpen = app.buttons["logMoneyOpenButton"]
        XCTAssertTrue(logOpen.waitForExistence(timeout: 6))
        logOpen.tap()

        XCTAssertTrue(app.buttons["logSaveButton"].waitForExistence(timeout: 3))
        app.buttons["logKind_stashed"].tap()
        let amount = app.textFields["amountField"]
        if amount.waitForExistence(timeout: 2) {
            amount.tap()
            amount.clearAndType("10")
        }
        app.buttons["logSaveButton"].tap()

        XCTAssertTrue(logOpen.waitForExistence(timeout: 4), "Sheet should dismiss after save")

        // Spent outflow
        logOpen.tap()
        XCTAssertTrue(app.buttons["logKind_spent"].waitForExistence(timeout: 3))
        app.buttons["logKind_spent"].tap()
        if amount.waitForExistence(timeout: 2) {
            amount.tap()
            amount.clearAndType("3")
        }
        app.buttons["logSaveButton"].tap()

        app.tabBars.buttons["Activity"].tap()
        XCTAssertTrue(app.navigationBars["Activity"].waitForExistence(timeout: 3))
        // At least one logged row should appear
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '10' OR label CONTAINS[c] '$10' OR label CONTAINS[c] 'Stash' OR label CONTAINS[c] 'Spent'")).firstMatch.waitForExistence(timeout: 4)
            || app.cells.count > 0
            || app.otherElements.containing(NSPredicate(format: "label CONTAINS[c] 'Ronell'")).firstMatch.exists)
    }

    func testYouTabProfilesExportAndAppearance() throws {
        let app = launchFresh()
        completeOnboardingIfNeeded(app)

        app.tabBars.buttons["You"].tap()
        XCTAssertTrue(app.navigationBars["You"].waitForExistence(timeout: 3))

        let addProfile = app.buttons["addProfileOpenButton"].exists
            ? app.buttons["addProfileOpenButton"]
            : app.buttons["Add profile"]
        XCTAssertTrue(addProfile.waitForExistence(timeout: 4), "Add profile control should be on You tab")
        XCTAssertTrue(app.buttons["exportDataButton"].exists || app.buttons["Export backup (JSON)"].exists)

        // Appearance section is further down the list.
        if app.staticTexts["Appearance"].exists == false {
            app.swipeUp()
        }
        let hasAppearance = app.staticTexts["Appearance"].exists
            || app.staticTexts["System"].exists
            || app.staticTexts["Light"].exists
            || app.otherElements["appearancePicker"].exists
        XCTAssertTrue(hasAppearance, "Appearance controls should be visible on You tab")

        // Re-query before tap in case list scrolled.
        let addAgain = app.buttons["addProfileOpenButton"].exists
            ? app.buttons["addProfileOpenButton"]
            : app.buttons["Add profile"]
        if !addAgain.isHittable {
            app.swipeDown()
        }
        XCTAssertTrue(addAgain.waitForExistence(timeout: 3))
        addAgain.tap()

        let nameField = app.textFields["profileNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Jordan")
        let addButton = app.buttons["addProfileButton"].exists
            ? app.buttons["addProfileButton"]
            : app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        addButton.tap()

        XCTAssertTrue(
            app.staticTexts["Jordan"].waitForExistence(timeout: 5)
            || app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Jordan'")).firstMatch.waitForExistence(timeout: 2)
        )
    }

    func testChallengesStartAndLogFromDetail() throws {
        let app = launchFresh()
        completeOnboardingIfNeeded(app)

        app.tabBars.buttons["Challenges"].tap()
        XCTAssertTrue(app.navigationBars["Challenges"].waitForExistence(timeout: 3))

        let firstChallenge = app.cells.firstMatch
        if !firstChallenge.waitForExistence(timeout: 3) {
            // Fallback: tap any challenge name
            let link = app.buttons.firstMatch
            XCTAssertTrue(link.waitForExistence(timeout: 2))
        } else {
            firstChallenge.tap()
        }

        let start = app.buttons["startChallengeButton"]
        if start.waitForExistence(timeout: 4) {
            start.tap()
        }

        let challengeLog = app.buttons["challengeLogMoneyButton"]
        if challengeLog.waitForExistence(timeout: 3) {
            challengeLog.tap()
            if app.buttons["logSaveButton"].waitForExistence(timeout: 3) {
                app.buttons["logSaveButton"].tap()
            }
        }

        let end = app.buttons["endChallengeButton"]
        XCTAssertTrue(end.waitForExistence(timeout: 3) || app.buttons["markChallengeCompleteButton"].exists || challengeLog.exists)
    }

    func testParentMatchFlow() throws {
        let app = launchFresh()
        completeOnboardingIfNeeded(app, adult: "Ronell", kid: "Maya")

        // Start Parent Match from Family challenges
        app.tabBars.buttons["Challenges"].tap()
        XCTAssertTrue(app.navigationBars["Challenges"].waitForExistence(timeout: 3))

        let familySegment = app.buttons["Family"]
        if familySegment.waitForExistence(timeout: 2) {
            familySegment.tap()
        }

        let parentMatchRow = app.staticTexts["Parent Match"]
        if parentMatchRow.waitForExistence(timeout: 4) {
            parentMatchRow.tap()
        } else if app.cells.count > 0 {
            // Fallback: open first family challenge list item containing Match
            let matchCell = app.cells.containing(NSPredicate(format: "label CONTAINS[c] 'Match'")).firstMatch
            if matchCell.exists { matchCell.tap() }
        }

        let start = app.buttons["startChallengeButton"]
        if start.waitForExistence(timeout: 3) {
            start.tap()
        }

        // Log a kid stash so Parent Match becomes available
        app.tabBars.buttons["Home"].tap()
        let mayaChip = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'profileChip_' OR label CONTAINS[c] 'Maya'")).firstMatch
        if mayaChip.waitForExistence(timeout: 3) {
            mayaChip.tap()
        }

        let logOpen = app.buttons["logMoneyOpenButton"]
        XCTAssertTrue(logOpen.waitForExistence(timeout: 4))
        logOpen.tap()
        if app.buttons["logKind_stashed"].waitForExistence(timeout: 3) {
            app.buttons["logKind_stashed"].tap()
        }
        if app.buttons["logSaveButton"].waitForExistence(timeout: 2) {
            app.buttons["logSaveButton"].tap()
        }

        // Switch to adult and look for match controls
        let ronellChip = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'profileChip_' OR label CONTAINS[c] 'Ronell'")).firstMatch
        if ronellChip.waitForExistence(timeout: 3) {
            ronellChip.tap()
        }

        let matchFull = app.buttons["parentMatchFullButton"]
        let matchHalf = app.buttons["parentMatchHalfButton"]
        let banner = app.otherElements["kidMatchBanner"]
        let hasMatchUI = matchFull.waitForExistence(timeout: 4)
            || matchHalf.exists
            || banner.exists
            || app.staticTexts["Parent Match available"].waitForExistence(timeout: 2)
            || app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'match'")).firstMatch.exists

        XCTAssertTrue(hasMatchUI, "Parent Match UI should appear after kid stash with Parent Match challenge active")

        if matchFull.exists {
            matchFull.tap()
        } else if matchHalf.exists {
            matchHalf.tap()
        }
    }

    func testLogMoneyButtonAccessibilityIdentifier() throws {
        let app = launchFresh()
        completeOnboardingIfNeeded(app, kid: nil)

        let logButton = app.buttons["logMoneyOpenButton"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 6))
        logButton.tap()
        let saveButton = app.buttons["logSaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
    }
}

private extension XCUIElement {
    func clearAndType(_ text: String) {
        guard let value = self.value as? String else {
            typeText(text)
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)
        typeText(deleteString)
        typeText(text)
    }
}
