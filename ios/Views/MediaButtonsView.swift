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
import LiveSharingTestAppModels
import SwiftUI

/// Buttons exposing control of the media playback.
///
/// Allows the user to play, pause and restart the media. The play and pause button alternate based
/// on the current playback state of the media player (shows play button if the media is paused and
/// the pause button if the media is playing).
struct MediaButtonsView: View {
  @EnvironmentObject public var mediaPlayer: MediaPlayer
  public var buttonColor: Color
  private var playPauseAction: () -> Void {
    mediaPlayer.playbackState == .playing ? mediaPlayer.pause : mediaPlayer.play
  }
  private var playPauseIcon: Image {
    mediaPlayer.playbackState == .playing
      ? Image("system_icons_gm_filled/pause_24pt") : Image("system_icons_gm_filled/play_arrow_24pt")
  }

  var body: some View {
    HStack {
      Button(action: playPauseAction) {
        playPauseIcon
      }
      Button(action: mediaPlayer.restart) {
        Image("system_icons_gm_filled/replay_24pt")
      }
    }.buttonStyle(MediaButtonStyle(buttonColor: buttonColor))
  }
}

struct MediaButtonsView_Previews: PreviewProvider {
  static var previews: some View {
    MediaButtonsView(buttonColor: Color.blue)
  }
}
