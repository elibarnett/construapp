//
//  ConstruAppUITests.swift
//  ConstruAppUITests
//
//  Created by Eli Barnett on 8/4/25.
//

import XCTest

final class ConstruAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testGalleryFilterByCategory() throws {
        // 1. Navigate from project list to the first project's detail view
        app.collectionViews.buttons.firstMatch.tap()

        // 2. Navigate to the media gallery
        // I need to find the gallery button. Based on my previous exploration, there should be one.
        // I'll assume the button is labeled "View Media Gallery".
        let galleryButton = app.buttons["View Media Gallery"]
        XCTAssert(galleryButton.waitForExistence(timeout: 5), "Gallery button not found")
        galleryButton.tap()

        // 3. Open the category filter sheet
        app.buttons["Category"].tap()

        // 4. Deselect all categories to start clean
        let deselectAllButton = app.buttons["Deselect All"]
        if deselectAllButton.exists {
            deselectAllButton.tap()
        } else {
            // If it's "Select All", tap it twice to deselect all
            let selectAllButton = app.buttons["Select All"]
            selectAllButton.tap()
            selectAllButton.tap()
        }

        // 5. Select the "Electrical" category
        app.tables.staticTexts["Electrical"].tap()

        // 6. Close the sheet
        app.navigationBars["Select Categories"].buttons["Done"].tap()

        // 7. Verify the "Electrical" filter chip is now visible
        XCTAssert(app.staticTexts["Electrical"].exists)

        // 8. Tap the chip to remove the filter
        // The chip itself is a button now in my implementation.
        app.buttons["Electrical"].tap()

        // 10. Verify the chip is gone
        XCTAssertFalse(app.staticTexts["Electrical"].exists)
    }
}
