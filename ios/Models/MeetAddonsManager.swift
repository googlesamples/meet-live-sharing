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

/// Entry point for all Meet Addons functionality within the app.
public class MeetAddonsManager: ObservableObject {
  enum Constants {
    static let positionBuffer: TimeInterval = 0.25
  }

  public static let shared: MeetAddonsManager = MeetAddonsManager()

  private let logger: Logger = Logger.shared

  /// The add-on client used for interacting with Meet.
  private let addonClient: AddonClient = AddonClient.shared
  /// The current add-on session, if one is ongoing in Meet and the test app is participating in it.
  private var addonSession: AddonSession?
  /// True if the add-on session has begun
  @Published public var addonSessionHasBegun: Bool = false

  /// Data managed by the test app.
  let appState: AppState = AppState.shared
  let mediaPlayer: MediaPlayer = MediaPlayer.shared
  var isThemeGreen: Bool {
    appState.themeColor == .testAppEmerald
  }

  init() {
    appState.delegate = self
    mediaPlayer.delegate = self

    NotificationCenter.default.addObserver(
      self, selector: #selector(handleMeetingStateDidChange(_:)),
      name: .addonMeetingStateDidChange,
      object: nil)
    addonClient.initialize(cloudProjectNumber: 583_859_152_812)
  }

  /// Begins a new add-on session, if one does not already exist.
  public func beginAddonSession() {
    guard addonSession == nil else {
      return
    }

    logger.log("Beginning AddonSession.")

    let addonSession = addonClient.makeSession(
      coDoingHandler: self, coWatchingHandler: self)
    self.addonSession = addonSession
    NotificationCenter.default.addObserver(
      self, selector: #selector(handleAddonSessionDidBegin(_:)),
      name: .addonSessionDidBegin,
      object: addonSession)

    NotificationCenter.default.addObserver(
      self, selector: #selector(handleAddonSessionDidEnd(_:)),
      name: .addonSessionDidEnd,
      object: addonSession)

    NotificationCenter.default.addObserver(
      self, selector: #selector(handleAddonSessionRuntimeError(_:)),
      name: .addonSessionRuntimeError,
      object: addonSession)

    addonSession.begin()
  }

  /// Ends the current add-on session, if one exists.
  public func endAddonSession() {
    guard let addonSession else {
      logger.log("endAddonSession() called when no session active.")
      return
    }

    addonSession.end()
  }

  @objc func handleMeetingStateDidChange(_ notification: Notification) {
    DispatchQueue.main.async {
      guard
        let meetingInfo =
          notification.userInfo?[addonMeetingStateChangedUserInfoKey]
          as? AddonMeetingInfo
      else {
        self.logger.log("addonMeetingStateDidChange posted without meeting info.")
        return
      }

      self.logger.log(
        """
        Meeting state updated -> AddonMeetingInfo(detectionState: \(meetingInfo.detectionState),
        code: "\(String(describing: meetingInfo.code))", url: \(String(describing: meetingInfo.url)).
        """
      )
    }
  }

  @objc func handleAddonSessionDidBegin(_ notification: Notification) {
    DispatchQueue.main.async {
      guard let addonSession = self.addonSession,
        let session = notification.object as? AddonSession,
        session === addonSession
      else {
        self.logger.log(
          "addonSessionDidBegin received for session other than current session.")
        return
      }

      self.addonSessionHasBegun = true

      self.logger.log("AddonSession began.")
    }
  }

  @objc func handleAddonSessionDidEnd(_ notification: Notification) {
    DispatchQueue.main.async {
      guard let addonSession = self.addonSession,
        let session = notification.object as? AddonSession,
        session === addonSession,
        let reason = notification.userInfo?[addonSessionEndReasonUserInfoKey]
          as? AddonSessionEndReason
      else {
        self.logger.log(
          "addonSessionDidEnd received for session other than current session.")
        return
      }

      self.cleanupAddonSession()
      self.logger.log("AddonSession ended for reason: \(String(describing: reason)).")
    }
  }

  @objc func handleAddonSessionRuntimeError(_ notification: Notification) {
    DispatchQueue.main.async {
      guard let addonSession = self.addonSession,
        let session = notification.object as? AddonSession, session === addonSession
      else {
        self.logger.log(
          "addonSessionRuntimeError posted for session other than current session.")
        return
      }

      let error = notification.userInfo?[addonSessionRuntimeErrorUserInfoKey] as? Error
      if error == nil {
        self.logger.log(
          "addonSessionRuntimeError posted without error.")
        return
      }

      self.cleanupAddonSession()
      self.logger.log("AddonSession encountered runtime error: \(error).")
    }
  }

  private func cleanupAddonSession() {
    dispatchPrecondition(condition: .onQueue(.main))

    NotificationCenter.default.removeObserver(
      self,
      name: .addonSessionDidBegin,
      object: addonSession)

    NotificationCenter.default.removeObserver(
      self,
      name: .addonSessionDidEnd,
      object: addonSession)

    NotificationCenter.default.removeObserver(
      self,
      name: .addonSessionRuntimeError,
      object: addonSession)

    addonSessionHasBegun = false
    addonSession = nil
  }

  public func getAddonUIActivity() -> UIActivity {
    return addonClient.addonUIActivity
  }
}

// MARK: - CoDoingHandler

extension MeetAddonsManager: CoDoingHandler {
  public func apply(updated state: CoDoingState) {
    let dataString: String = String(decoding: state.state, as: UTF8.self)
    if !addonSessionHasBegun {
      logger.log("Received initial co-doing state -> CoDoingState(state: \(dataString)).")
    } else {
      logger.log("Received co-doing update -> CoDoingState(state: \(dataString)).")
    }

    guard let isThemeGreen = Bool(dataString) else {
      logger.log("Received malformed co-doing state!")
      return
    }
    appState.themeColor = isThemeGreen ? .testAppEmerald : .blue
  }
}

// MARK: - CoWatchingHandler

extension MeetAddonsManager: CoWatchingHandler {
  public func queryCoWatchingState() -> (any QueryableCoWatchingStateProtocol)? {
    return CoWatchingState(mediaPlayer: mediaPlayer)
  }

  public func apply(updated state: CoWatchingState) {
    if !addonSessionHasBegun {
      logger.log(
        """
        Received initial co-watching state -> CoWatchingState(mediaID: \(state.mediaID), \
        mediaPlayoutPosition: \(state.mediaPlayoutPosition), \
        mediaPlayoutRate: \(state.mediaPlayoutRate), \
        mediaPlayoutState: \(state.mediaPlaybackState)).
        """
      )
    } else {
      logger.log(
        """
        Received co-watching update -> CoWatchingState(mediaID: \(state.mediaID), \
        mediaPlayoutPosition: \(state.mediaPlayoutPosition), \
        mediaPlayoutRate: \(state.mediaPlayoutRate), \
        mediaPlayoutState: \(state.mediaPlaybackState)).
        """
      )
    }

    if self.mediaPlayer.selectedMedia?.name != state.mediaID {
      self.mediaPlayer.selectedMedia = Medias.getMedia(
        mediaName: state.mediaID)
    }
    if !self.rangeContainsPosition(state.mediaPlayoutPosition) {
      self.mediaPlayer.set(position: state.mediaPlayoutPosition)
    }
    if self.mediaPlayer.playbackState
      != MediaPlayer.PlaybackState(playbackState: state.mediaPlaybackState)
    {
      self.mediaPlayer.playbackState = MediaPlayer.PlaybackState(
        playbackState: state.mediaPlaybackState)
    }
    if self.mediaPlayer.playoutRate != state.mediaPlayoutRate {
      self.mediaPlayer.playoutRate = state.mediaPlayoutRate
    }
  }
}

// MARK: - MediaPlayerDelegate

extension MeetAddonsManager: MediaPlayerDelegate {
  public func mediaPlayer(
    _ mediaPlayer: MediaPlayer, didChangeMedia newMedia: Media, at position: TimeInterval
  ) {
    do {
      try addonSession?.coWatchingClient?.notifySwitchTo(
        title: newMedia.name, id: newMedia.name, at: position)
    } catch {
      logger.log("Error while broadcasting media switch -> \(error)")
    }
  }

  public func mediaPlayer(
    _ mediaPlayer: MediaPlayer, didUpdatePlaybackState newPlaybackState: MediaPlayer.PlaybackState,
    at position: TimeInterval
  ) {
    do {
      switch newPlaybackState {
      case .playing:
        try addonSession?.coWatchingClient?.notifyPlaying(at: position)
      case .paused:
        try addonSession?.coWatchingClient?.notifyPaused(at: position)
      case .buffering:
        try addonSession?.coWatchingClient?.notifyBuffering(at: position)
      case .ended:
        try addonSession?.coWatchingClient?.notifyEnded(at: position)
      }
    } catch {
      logger.log("Error while broadcasting new playback state -> \(error)")
    }
  }

  public func mediaPlayer(
    _ mediaPlayer: MediaPlayer, didUpdatePlaybackPosition newPosition: TimeInterval
  ) {
    do {
      try addonSession?.coWatchingClient?.notifySeek(to: newPosition)
    } catch {
      logger.log("Error while broadcasting new playback position -> \(error)")
    }
  }
}

// MARK: - AppStateDelegate

extension MeetAddonsManager: AppStateDelegate {
  public func appState(_ appState: AppState, didSwitchColors newColor: Color) {
    do {
      try addonSession?.coDoingClient?.set(global: CoDoingState(isThemeGreen: isThemeGreen))
    } catch {
      logger.log("Error while broadcasting update to color -> \(error)")
    }
  }

  /// Performs a fuzzy equality comparison to check if the specified position is within a certain
  /// range of the media player position.
  ///
  /// We perform this fuzzy comparison because of the lack of precision in floating point
  /// comparisons. We also allow a small amount of tolerance (+/- .25 seconds) in order to prevent
  /// unnecessary updates to the media player's position. Adjust this comparison per your needs.
  ///
  /// - Parameter position: The position being checked.
  private func rangeContainsPosition(_ position: TimeInterval) -> Bool {
    let currentPosition = self.mediaPlayer.currentPosition
    let lowerBound = currentPosition - Constants.positionBuffer
    let upperBound = currentPosition + Constants.positionBuffer
    let positionRange = lowerBound...upperBound
    return positionRange.contains(position)
  }
}

/// Uses AppState to create an instance of CoDoingState.
extension CoDoingState {
  init(isThemeGreen: Bool) {
    let coDoingData: Data =
      String(isThemeGreen).data(using: .utf8) ?? Data()
    self.init(state: coDoingData)
  }
}

/// Uses MediaPlayer to create an instance of CoWatchingState.
extension CoWatchingState {
  init?(mediaPlayer: MediaPlayer) {
    guard let selectedMedia = mediaPlayer.selectedMedia else {
      return nil
    }

    self.init(
      mediaID: selectedMedia.name,
      mediaPlayoutPosition: mediaPlayer.currentPosition,
      mediaPlayoutRate: mediaPlayer.playoutRate,
      mediaPlaybackState: CoWatchingState.PlaybackState(playbackState: mediaPlayer.playbackState)
    )
  }
}

/// Initializer used to convert CoWatchingState's playback state to an instance of MediaPlayer's
/// playback state.
extension MediaPlayer.PlaybackState {
  init(playbackState: CoWatchingState.PlaybackState) {
    switch playbackState {
    case .playing:
      self = MediaPlayer.PlaybackState.playing
    case .paused:
      self = MediaPlayer.PlaybackState.paused
    case .buffering:
      self = MediaPlayer.PlaybackState.buffering
    case .ended:
      self = MediaPlayer.PlaybackState.ended
    }
  }
}

/// Initializer used to convert MediaPlayer's playback state to an instance of CoWatchingState's
/// playback state.
extension CoWatchingState.PlaybackState {
  init(playbackState: MediaPlayer.PlaybackState) {
    switch playbackState {
    case .playing:
      self = CoWatchingState.PlaybackState.playing
    case .paused:
      self = CoWatchingState.PlaybackState.paused
    case .buffering:
      self = CoWatchingState.PlaybackState.buffering
    case .ended:
      self = CoWatchingState.PlaybackState.ended
    }
  }
}
