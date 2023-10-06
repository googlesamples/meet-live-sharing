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

final class MediaPlayerTest: XCTestCase {
  enum Constants {
    static let testMedia1 = Media(name: "Test Media 1", duration: 15)
    static let testMedia2 = Media(name: "Test Media 2", duration: 100)
  }

  private var mediaPlayer: MediaPlayer = MediaPlayer()

  override func setUp() {
    super.setUp()
    mediaPlayer = MediaPlayer()
  }

  func testChangeMedia() {
    mediaPlayer.currentPosition = 5.4
    XCTAssertEqual(mediaPlayer.currentPosition, 5.4)
    XCTAssertNil(mediaPlayer.selectedMedia)
    XCTAssertEqual(mediaPlayer.playbackState, .paused)

    mediaPlayer.change(to: Constants.testMedia1)
    XCTAssertEqual(mediaPlayer.selectedMedia?.name, "Test Media 1")
    XCTAssertEqual(mediaPlayer.maxProgress, 15)
    XCTAssertEqual(mediaPlayer.currentPosition, 0.0)
    XCTAssertEqual(mediaPlayer.playbackState, .playing)

    mediaPlayer.change(to: Constants.testMedia2)
    XCTAssertEqual(mediaPlayer.selectedMedia?.name, "Test Media 2")
    XCTAssertEqual(mediaPlayer.maxProgress, 100)
  }

  func testSetMediaPosition() {
    mediaPlayer.change(to: Constants.testMedia1)
    XCTAssertEqual(mediaPlayer.currentPosition, 0.0)

    mediaPlayer.set(position: 3.0)
    XCTAssertEqual(mediaPlayer.currentPosition, 3.0)
  }

  func testSetMediaPositionWhenNoMediaSelected() {
    mediaPlayer.set(position: 3.0)
    XCTAssertEqual(mediaPlayer.currentPosition, 0.0)
  }

  func testSetMediaPositionAboveMaxProgress() {
    mediaPlayer.change(to: Constants.testMedia1)

    // Media 1's max progress is 15.0
    mediaPlayer.set(position: 16.0)
    XCTAssertEqual(mediaPlayer.currentPosition, 0.0)
  }

  func testSetMediaPositionWhenSeeking() {
    mediaPlayer.change(to: Constants.testMedia1)
    mediaPlayer.set(position: 8.0)

    mediaPlayer.isSeeking = true
    mediaPlayer.set(position: 10.0)
    XCTAssertEqual(mediaPlayer.currentPosition, 8.0)
  }

  func testSetMediaPositionWhenEnded() {
    mediaPlayer.change(to: Constants.testMedia1)
    mediaPlayer.playbackState = .ended

    mediaPlayer.set(position: 10.0)
    XCTAssertEqual(mediaPlayer.playbackState, .paused)
  }

  func testPlayMedia() {
    mediaPlayer.change(to: Constants.testMedia1)
    mediaPlayer.playbackState = .paused

    mediaPlayer.play()
    XCTAssertEqual(mediaPlayer.playbackState, .playing)
  }

  func testPlayMediaWhenNoMediaSelected() {
    mediaPlayer.play()
    XCTAssertEqual(mediaPlayer.playbackState, .paused)
  }

  func testPlayMediaWhenEnded() {
    mediaPlayer.change(to: Constants.testMedia1)
    mediaPlayer.set(position: 10.0)
    mediaPlayer.playbackState = .ended

    mediaPlayer.play()
    XCTAssertEqual(mediaPlayer.currentPosition, 0.0)
  }

  func testPauseMedia() {
    mediaPlayer.change(to: Constants.testMedia1)

    mediaPlayer.pause()
    XCTAssertEqual(mediaPlayer.playbackState, .paused)
  }

  func testPauseMediaWhenEnded() {
    mediaPlayer.change(to: Constants.testMedia1)
    mediaPlayer.playbackState = .ended

    mediaPlayer.pause()
    XCTAssertEqual(mediaPlayer.playbackState, .ended)
  }

  func testRestartMedia() {
    mediaPlayer.change(to: Constants.testMedia1)
    mediaPlayer.set(position: 10.0)

    mediaPlayer.restart()
    XCTAssertEqual(mediaPlayer.currentPosition, 0.0)
  }

  func testSimulatePlayback() {
    mediaPlayer.change(to: Constants.testMedia1)
    XCTAssertEqual(mediaPlayer.currentPosition, 0.0)

    let expectation = self.expectation(description: "Simulating playback for 2 seconds")
    let expectedTime: Double = 2

    DispatchQueue.main.asyncAfter(deadline: .now() + expectedTime) {
      expectation.fulfill()
    }

    // Adds 1 second to give the expectation time to fulfill.
    waitForExpectations(timeout: expectedTime + 1)

    XCTAssertEqual(mediaPlayer.currentPosition.rounded(), 2.0)
  }

  func testSimulatePlaybackWhenSeeking() {
    mediaPlayer.change(to: Constants.testMedia1)

    mediaPlayer.isSeeking = true
    let expectation = self.expectation(description: "Simulating playback for 2 seconds")
    let expectedTime: Double = 2

    DispatchQueue.main.asyncAfter(deadline: .now() + expectedTime) {
      expectation.fulfill()
    }

    waitForExpectations(timeout: expectedTime + 1)
    XCTAssertEqual(mediaPlayer.currentPosition.rounded(), 0.0)
  }

  func testSimulatePlaybackWhenMaxProgressReached() {
    mediaPlayer.change(to: Constants.testMedia1)

    mediaPlayer.currentPosition = 14.0
    let expectation = self.expectation(description: "Simulating playback for 2 seconds")
    let expectedTime: Double = 2

    DispatchQueue.main.asyncAfter(deadline: .now() + expectedTime) {
      expectation.fulfill()
    }

    waitForExpectations(timeout: expectedTime + 1)
    XCTAssertEqual(mediaPlayer.playbackState, .ended)
  }
}
