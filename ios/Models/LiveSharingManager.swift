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

/// Entry point for all live sharing functionality within the app.
public class LiveSharingManager: ObservableObject {
  enum Constants {
    static let positionBuffer: TimeInterval = 0.25
  }

  public static let shared: LiveSharingManager = LiveSharingManager()

  private let logger: Logger = Logger.shared

  let liveSharingClient: LiveSharingClient = LiveSharingClient.shared
  let appState: AppState = AppState.shared
  let mediaPlayer: MediaPlayer = MediaPlayer.shared

  private var coDoingSession: CoDoingSession? {
    didSet {
      isCoDoing = coDoingSession != nil
    }
  }

  private var coWatchingSession: CoWatchingSession? {
    didSet {
      isCoWatching = coWatchingSession != nil
    }
  }

  private var isThemeGreen: Bool {
    appState.themeColor == .testAppEmerald
  }

  private var meetingInfo: LiveSharingMeetingInfo? {
    didSet {
      isConnectedToMeeting = meetingInfo != nil
      // Ends the co-watching and co-doing session if we leave the meeting.
      guard meetingInfo == nil else { return }
      coDoingSession = nil
      coWatchingSession = nil
    }
  }

  @Published public var isConnectedToMeeting: Bool = false
  @Published public var isCoDoing: Bool = false
  @Published public var isCoWatching: Bool = false

  init() {
    appState.delegate = self
    mediaPlayer.delegate = self
  }

  /// Informs the live sharing client to connect to an on-going meeting (if one exists).
  public func connectToMeeting() {
    logger.log("Attempting to connect to meeting.")
    liveSharingClient.connectToMeeting { [weak self] meetingInfo, error in
      guard let self = self else { return }
      guard error == nil else {
        self.logger.log("Error while connecting to meeting -> \(error.debugDescription)")
        return
      }
      DispatchQueue.main.async {
        self.meetingInfo = meetingInfo
        guard let state = meetingInfo?.state,
          let code = meetingInfo?.code,
          let url = meetingInfo?.url
        else {
          self.logger.log(
            """
            Connected to the meeting with malformed LiveSharingMeetingInfo (\
            state: \(String(describing: meetingInfo?.state)), \
            code: "\(String(describing: meetingInfo?.code))", \
            url: \(String(describing: meetingInfo?.url)).
            """
          )
          return
        }
        self.logger.log(
          """
          Connected to the meeting -> LiveSharingMeetingInfo(state: \(state), \
          code: "\(code)", url: \(url)).
          """
        )
        self.startCoDoing()
        self.startCoWatching()
      }
    }
  }

  /// Informs the live sharing client to disconnect from an ongoing meeting if one has been
  /// connected to.
  public func disconnectFromMeeting() {
    liveSharingClient.disconnectFromMeeting { [weak self] error in
      guard let self = self else { return }
      if error != nil {
        self.logger.log(
          "Error in LiveSharingClient when disconnecting from meeting -> \(error.debugDescription)")
      }
      DispatchQueue.main.async {
        self.meetingInfo = nil
        self.logger.log("Disconnected from meeting.")
      }
    }
  }

  /// Attempts to local start a co-doing session within the meeting.
  ///
  /// If the a meeting hasn't been joined yet, then a co-doing session can't be started.
  public func startCoDoing() {
    guard isConnectedToMeeting && !isCoDoing else { return }
    logger.log("Starting co-doing session.")
    liveSharingClient.beginCoDoing(with: self) { [weak self] coDoingSession, error in
      guard let self = self else { return }
      guard error == nil else {
        self.logger.log("Error when starting a co-doing session -> \(error.debugDescription)")
        return
      }
      DispatchQueue.main.async {
        self.coDoingSession = coDoingSession
        self.logger.log("Started co-doing session.")
      }
    }
  }

  /// Attempts to start a local co-watching session within the meeting.
  ///
  /// If the a meeting hasn't been joined yet, then a co-watching session can't be started.
  public func startCoWatching() {
    guard isConnectedToMeeting && !isCoWatching else { return }
    logger.log("Starting co-watching session.")
    liveSharingClient.beginCoWatching(with: self) { [weak self] coWatchingSession, error in
      guard let self = self else { return }
      guard error == nil else {
        self.logger.log("Error when starting a co-watching session -> \(error.debugDescription)")
        return
      }
      DispatchQueue.main.async {
        self.coWatchingSession = coWatchingSession
        self.logger.log("Started co-watching session.")
      }
    }
  }

  /// Ends the local co-doing session, if one has been started.
  public func endCoDoing() {
    guard isCoDoing else { return }
    liveSharingClient.endCoDoing { [weak self] error in
      guard let self = self else { return }
      if error != nil {
        self.logger.log(
          "Error in LiveSharingClient when ending the co-doing session -> \(error.debugDescription)"
        )
      }
      DispatchQueue.main.async {
        self.coDoingSession = nil
        self.logger.log("Ended co-doing session.")
      }
    }
  }

  /// Ends the local co-watching session, if one has been started.
  public func endCoWatching() {
    guard isCoWatching else { return }
    liveSharingClient.endCoWatching { [weak self] error in
      guard let self = self else { return }
      if error != nil {
        self.logger.log(
          """
          Error in LiveSharingClient when ending the co-watching session -> \
          \(error.debugDescription)
          """
        )
      }
      DispatchQueue.main.async {
        self.coWatchingSession = nil
        self.logger.log("Ended co-watching session.")
      }
    }
  }

  public func getLiveSharingUIActivity() -> UIActivity {
    return liveSharingClient.liveSharingUIActivity
  }

}

// MARK: - CoDoingSessionDelegate

extension LiveSharingManager: CoDoingSessionDelegate {
  public func localState(for session: CoDoingSession) -> CoDoingState? {
    return CoDoingState(isThemeGreen: isThemeGreen)
  }

  public func coDoingSession(_ session: CoDoingSession, apply state: CoDoingState) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      let dataString: String = String(decoding: state.state, as: UTF8.self)
      self.logger.log("Received co-doing update -> CoDoingState(state: \(dataString)).")
      let isThemeGreen = Bool(dataString)
      guard let isThemeGreen = isThemeGreen, isThemeGreen != self.isThemeGreen else { return }
      self.appState.themeColor = isThemeGreen ? .testAppEmerald : .blue
    }
  }
}

// MARK: - CoWatchingSessionDelegate

extension LiveSharingManager: CoWatchingSessionDelegate {
  public func localState(for session: CoWatchingSession) -> CoWatchingState? {
    return CoWatchingState(mediaPlayer: mediaPlayer)
  }

  public func coWatchingSession(_ session: CoWatchingSession, apply state: CoWatchingState) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.logger.log(
        """
        Received co-watching update -> CoWatchingState(mediaID: \(state.mediaID), \
        mediaPlayoutPosition: \(state.mediaPlayoutPosition), \
        mediaPlayoutRate: \(state.mediaPlayoutRate), \
        mediaPlayoutState: \(state.mediaPlaybackState)).
        """
      )
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
}

// MARK: - MediaPlayerDelegate

extension LiveSharingManager: MediaPlayerDelegate {
  public func mediaPlayer(
    _ mediaPlayer: MediaPlayer, didChangeMedia newMedia: Media, at position: TimeInterval
  ) {
    do {
      try coWatchingSession?.notifySwitchToMedia(
        withTitle: newMedia.name, mediaID: newMedia.name, at: position)
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
        try coWatchingSession?.notifyPauseState(false, at: position)
      case .paused:
        try coWatchingSession?.notifyPauseState(true, at: position)
      case .buffering:
        try coWatchingSession?.notifyBuffering(at: position)
      case .ended:
        try coWatchingSession?.notifyEnded(at: position)
      }
    } catch {
      logger.log("Error while broadcasting new playback state -> \(error)")
    }
  }

  public func mediaPlayer(
    _ mediaPlayer: MediaPlayer, didUpdatePlaybackPosition newPosition: TimeInterval
  ) {
    do {
      try coWatchingSession?.notifySeek(to: newPosition)
    } catch {
      logger.log("Error while broadcasting new playback position -> \(error)")
    }
  }
}

// MARK: - AppStateDelegate

extension LiveSharingManager: AppStateDelegate {
  public func appState(_ appState: AppState, didSwitchColors newColor: Color) {
    do {
      try coDoingSession?.broadcast(CoDoingState(isThemeGreen: isThemeGreen))
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
  /// Parameter position: The position being checked.
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
  init(mediaPlayer: MediaPlayer) {
    let mediaID = mediaPlayer.selectedMedia?.name ?? ""
    self.init(
      mediaID: mediaID,
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
