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
import SwiftUI

public protocol MediaPlayerDelegate: AnyObject {
  func mediaPlayer(
    _ mediaPlayer: MediaPlayer, didChangeMedia newMedia: Media, at position: TimeInterval)

  func mediaPlayer(
    _ mediaPlayer: MediaPlayer, didUpdatePlaybackState newPlaybackState: MediaPlayer.PlaybackState,
    at position: TimeInterval)

  func mediaPlayer(_ mediaPlayer: MediaPlayer, didUpdatePlaybackPosition newPosition: TimeInterval)
}

/// Model containing logic for media playback simulation.
public class MediaPlayer: ObservableObject {
  /// Possible states of the media playback.
  public enum PlaybackState {
    case playing
    case paused
    case buffering
    case ended
  }

  public static let shared: MediaPlayer = MediaPlayer()

  public weak var delegate: MediaPlayerDelegate?

  private var mediaProgressTimer: Timer?
  private var seekingState: PlaybackState?
  @Published public var selectedMedia: Media? = nil {
    didSet {
      guard let selectedMedia = selectedMedia else { return }
      // When a media is changed we update the max progress, set the playback state to play and
      // reset the current position to 0.
      maxProgress = selectedMedia.duration
      currentPosition = 0.0
      playbackState = .playing
    }
  }
  @Published public var playbackState: PlaybackState = .paused {
    didSet {
      switch playbackState {
      case .playing:
        simulatePlayback()
      case .paused, .ended:
        mediaProgressTimer?.invalidate()
        mediaProgressTimer = nil
      default:
        return
      }
    }
  }
  @Published public var currentPosition: TimeInterval = 0.0
  @Published public var maxProgress: TimeInterval = 0.1
  public var isSeeking = false {
    didSet {
      if isSeeking {
        seekingState = playbackState
        playbackState = .paused
      } else {
        guard let oldPlaybackState = seekingState else { return }
        playbackState = oldPlaybackState
        seekingState = nil
      }
    }
  }
  public var playoutRate = 1.0

  init() {}

  /// Changes the media.
  ///
  /// - Parameter newMedia: The media being changed to.
  public func change(to newMedia: Media) {
    guard newMedia != selectedMedia else { return }
    selectedMedia = newMedia
    delegate?.mediaPlayer(self, didChangeMedia: newMedia, at: currentPosition)
  }

  /// Sets the media player to the specified position.
  ///
  /// - Parameter position: The new position that the player will potentially be set to.
  public func set(position: TimeInterval) {
    guard selectedMedia != nil && position <= maxProgress && !isSeeking else { return }
    currentPosition = position
    delegate?.mediaPlayer(self, didUpdatePlaybackPosition: position)
    if currentPosition != maxProgress && playbackState == .ended {
      playbackState = .paused
      delegate?.mediaPlayer(self, didUpdatePlaybackState: .paused, at: currentPosition)
    }
  }

  /// Plays the media if it is currently paused.
  public func play() {
    guard playbackState != .playing && selectedMedia != nil else { return }
    if playbackState == .ended {
      currentPosition = 0.0
    }
    playbackState = .playing
    delegate?.mediaPlayer(self, didUpdatePlaybackState: .playing, at: currentPosition)
  }

  /// Pauses the media if it is currently playing.
  public func pause() {
    guard playbackState == .playing && selectedMedia != nil else { return }
    playbackState = .paused
    delegate?.mediaPlayer(self, didUpdatePlaybackState: .paused, at: currentPosition)
  }

  /// Resets the media playback back to the beginning.
  public func restart() {
    guard selectedMedia != nil else { return }
    currentPosition = 0.0
    delegate?.mediaPlayer(self, didUpdatePlaybackPosition: 0.0)
  }

  /// Simulates playback through the creation of a scheduled timer that increases the media
  /// position by 0.1 every tick.
  private func simulatePlayback() {
    guard mediaProgressTimer == nil else { return }
    mediaProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
      [weak self] _ in
      guard let self = self else { return }
      guard self.playbackState == .playing else {
        self.playbackState = .paused
        return
      }

      // Ends the playback when the maximum progress has been reached.
      guard self.currentPosition < self.maxProgress else {
        self.currentPosition = self.maxProgress
        self.playbackState = .ended
        return
      }
      self.currentPosition += (0.1 * self.playoutRate)
    }
  }
}
