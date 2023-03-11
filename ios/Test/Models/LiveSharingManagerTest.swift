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
import LiveSharing
import SwiftUI
import XCTest

@testable import LiveSharingTestAppModels

final class LiveSharingManagerTest: XCTestCase {
  private var liveSharingManager: LiveSharingManager = LiveSharingManager()

  override func setUp() {
    super.setUp()
    liveSharingManager = LiveSharingManager()
  }

  func testConnectToMeeting() {}

  func testDisconnectFromMeeting() {}

  func testStartCoDoing() {}

  func testEndCoDoing() {}

  func testStartCoWatching() {}

  func testEndCoWatching() {}

  func testApplyCoDoingState() {
    let coDoingState = CoDoingState(state: "true".data(using: .utf8) ?? Data())
    liveSharingManager.coDoingSession(DummyCoDoingSession(), apply: coDoingState)

    let coDoingApplyExpectation = self.expectation(description: "Applied co-doing state")
    DispatchQueue.main.async {
      coDoingApplyExpectation.fulfill()
    }

    waitForExpectations(timeout: 1)
    XCTAssertEqual(liveSharingManager.appState.themeColor, Color.testAppEmerald)
  }

  func testApplyCoWatchingState() {
    let coWatchingState = CoWatchingState(
      mediaID: "media_1",
      mediaPlayoutPosition: 1.0,
      mediaPlayoutRate: 2.0,
      mediaPlaybackState: .playing)
    liveSharingManager.coWatchingSession(DummyCoWatchingSession(), apply: coWatchingState)

    let coWatchingApplyExpectation = self.expectation(description: "Applied co-watching state")
    DispatchQueue.main.async {
      coWatchingApplyExpectation.fulfill()
    }

    waitForExpectations(timeout: 1)

    let mediaPlayer = liveSharingManager.mediaPlayer
    XCTAssertEqual(mediaPlayer.selectedMedia, Medias.media1)
    XCTAssertEqual(mediaPlayer.currentPosition, 1.0)
    XCTAssertEqual(mediaPlayer.playoutRate, 2.0)
    XCTAssertEqual(mediaPlayer.playbackState, .playing)
  }

  func testLocalCoDoingState() {
    liveSharingManager.appState.themeColor = .blue
    let localCoDoingState = liveSharingManager.localState(for: DummyCoDoingSession())

    XCTAssertEqual(String(decoding: localCoDoingState!.state, as: UTF8.self), "false")
  }

  func testLocalCoWatchingState() {
    let mediaPlayer = liveSharingManager.mediaPlayer
    mediaPlayer.selectedMedia = Medias.media2
    mediaPlayer.currentPosition = 4.0
    mediaPlayer.playoutRate = 3.0

    let localCoWatchingState = liveSharingManager.localState(for: DummyCoWatchingSession())

    XCTAssertEqual(localCoWatchingState?.mediaID, "media_2")
    XCTAssertEqual(localCoWatchingState?.mediaPlaybackState, .playing)
    XCTAssertEqual(localCoWatchingState?.mediaPlayoutPosition, 4.0)
    XCTAssertEqual(localCoWatchingState?.mediaPlayoutRate, 3.0)
  }
}

class DummyCoDoingSession: CoDoingSession {
  var delegate: LiveSharing.CoDoingSessionDelegate?

  func broadcast(_ state: LiveSharing.CoDoingState) throws {}
}

class DummyCoWatchingSession: CoWatchingSession {
  var delegate: LiveSharing.CoWatchingSessionDelegate?

  func notifySwitchToMedia(withTitle mediaTitle: String, mediaID: String, at position: TimeInterval)
    throws
  {}
  func notifyPauseState(_ paused: Bool, at position: TimeInterval) throws {}
  func notifySeek(to position: TimeInterval) throws {}
  func notifyPlayoutRate(_ playoutRate: Double) throws {}
  func notifyBuffering(at position: TimeInterval) throws {}
  func notifyReady(at position: TimeInterval) throws {}
  func notifyEnded(at position: TimeInterval) throws {}
}
