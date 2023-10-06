/* Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import XCTest

@testable import MeetAddonsTestAppModels

final class LoggerTest: XCTestCase {
  func testLog() {
    let logger = Logger()
    XCTAssert(logger.logs.isEmpty)

    logger.log("testing")
    let expectation = self.expectation(description: "Giving the logger time to add log")
    let expectedTime: Double = 2
    DispatchQueue.main.asyncAfter(deadline: .now() + expectedTime) {
      expectation.fulfill()
    }

    // Adds 1 second to give the expectation time to fulfill.
    waitForExpectations(timeout: expectedTime + 1)

    XCTAssertEqual(logger.logs.count, 1)
  }
}
