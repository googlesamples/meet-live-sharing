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
import MeetAddonsTestAppModels
import SwiftUI

/// View for the media player.
///
/// Contains a slider that tracks the media progress, enabling the user to seek to a desired time.
/// Also creates the media buttons that allow for control of the media playback.
struct MediaPlayerView: View {
  @EnvironmentObject private var mediaPlayer: MediaPlayer
  @EnvironmentObject private var appState: AppState

  var body: some View {
    VStack {
      Slider(value: $mediaPlayer.currentPosition, in: 0...mediaPlayer.maxProgress, step: 0.1) {
        isEditing in
        // If the seeking has just begun, inform the media player that seeking has started.
        if isEditing {
          mediaPlayer.isSeeking = true
        } else {
          mediaPlayer.isSeeking = false
          mediaPlayer.set(position: mediaPlayer.currentPosition)
        }
      }
      .disabled(mediaPlayer.selectedMedia == nil)
      .accentColor(appState.themeColor)

      MediaButtonsView(buttonColor: appState.themeColor)
    }
    .padding([.top, .leading, .trailing])
  }
}

struct MediaPlayerView_Previews: PreviewProvider {
  static var previews: some View {
    MediaPlayerView()
      .environmentObject(MediaPlayer.shared)
      .environmentObject(AppState.shared)
  }
}
