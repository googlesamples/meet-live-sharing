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
import MeetAddons
import SwiftUI
import XCTest

@testable import MeetAddonsTestAppModels

final class MeetAddonsManagerTest: XCTestCase {
  private var meetAddonsManager: MeetAddonsManager = MeetAddonsManager()

  override func setUp() {
    super.setUp()
    meetAddonsManager = MeetAddonsManager()
  }

  func testConnectToMeeting() {}

  func testDisconnectFromMeeting() {}

  func testStartCoDoing() {}

  func testEndCoDoing() {}

  func testStartCoWatching() {}

  func testEndCoWatching() {}

  func testApplyCoDoingState() {
    let coDoingState = CoDoingState(state: "true".data(using: .utf8) ?? Data())
    meetAddonsManager.apply(updated: coDoingState)

    let coDoingApplyExpectation = self.expectation(description: "Applied co-doing state")
    DispatchQueue.main.async {
      coDoingApplyExpectation.fulfill()
    }

    waitForExpectations(timeout: 1)
    XCTAssertEqual(meetAddonsManager.appState.themeColor, Color.testAppEmerald)
  }

  func testApplyCoWatchingState() {
    let coWatchingState = CoWatchingState(
      mediaID: "media_1",
      mediaPlayoutPosition: 1.0,
      mediaPlayoutRate: 2.0,
      mediaPlaybackState: .playing)
    meetAddonsManager.apply(updated: coWatchingState)

    let coWatchingApplyExpectation = self.expectation(description: "Applied co-watching state")
    DispatchQueue.main.async {
      coWatchingApplyExpectation.fulfill()
    }

    waitForExpectations(timeout: 1)

    let mediaPlayer = meetAddonsManager.mediaPlayer
    XCTAssertEqual(mediaPlayer.selectedMedia, Medias.media1)
    XCTAssertEqual(mediaPlayer.currentPosition, 1.0)
    XCTAssertEqual(mediaPlayer.playoutRate, 2.0)
    XCTAssertEqual(mediaPlayer.playbackState, .playing)
  }

  func testLocalCoWatchingState() {
    let mediaPlayer = meetAddonsManager.mediaPlayer
    mediaPlayer.selectedMedia = Medias.media2
    mediaPlayer.currentPosition = 4.0
    mediaPlayer.playoutRate = 3.0

    let localCoWatchingState = meetAddonsManager.queryCoWatchingState()

    XCTAssertEqual(localCoWatchingState?.mediaPlayoutPosition, 4.0)
  }
}
