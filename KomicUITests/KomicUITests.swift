//
//  KomicUITests.swift
//  KomicUITests
//
//  Created by Zook Gek on 9/29/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

import XCTest

class KomicUITests: XCTestCase {
  
  var app :XCUIApplication {
    get {
      return XCUIApplication()
    }
  }
  
  override func setUp() {
    super.setUp()
  
    continueAfterFailure = false

    XCUIApplication().launch()
  }

  func testUserIsAbleToViewExistingGame() {
    
    let tablesQuery = app.tables
    tablesQuery.children(matching: .cell).element(boundBy: 0).children(matching: .textView).element.tap()
    app.buttons["ellipses icon"].tap()
    app.sheets.buttons["Cancel"].tap()
    
    let iconChevronLeftButton = app.buttons["icon chevron left"]
    iconChevronLeftButton.tap()
    tablesQuery.children(matching: .cell).element(boundBy: 2).children(matching: .textView).element.tap()
    iconChevronLeftButton.tap()
  }
  
  func testUserIsAbleToInitiateANewGame() {

    app.buttons["Start Writing"].tap()
    
    let tablesQuery = app.tables
    tablesQuery.staticTexts["Office Affairs"].tap()

    app.buttons["Really? OK..."].tap()
    app.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .collectionView).element.tap()
    app.buttons["Invite Friends"].tap()
    app.collectionViews.cells.otherElements.containing(.staticText, identifier:"Ida Skomorokho").images["UIRemoveControlMultiNotCheckedImage"].tap()
    app.navigationBars["Invite one player"].buttons["Send"].tap()
    
    let enterYourBitHereTwoSentenceLimitTextField = app.textFields["Enter your bit here (two-sentence limit)."]
    enterYourBitHereTwoSentenceLimitTextField.tap()
    enterYourBitHereTwoSentenceLimitTextField.typeText("This is the first sentence.\r")
    
    app.buttons["icon chevron left"].tap()
    
  }
}
