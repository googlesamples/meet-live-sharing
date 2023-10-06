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

/// View for the app's controlled buttons.
///
/// Uses the app's models in order to derive the state of each button. When these models change,
/// the state and appearance of the buttons will update accordingly. The action for each button
/// will trigger work within the respective model they are tied to.
struct ControlledButtonsView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var mediaPlayer: MediaPlayer
  @ObservedObject var meetAddonsManager: MeetAddonsManager

  private var media1ButtonState: ControlledButtonState {
    mediaPlayer.selectedMedia == Medias.media1 ? .active : .inactive
  }
  private var media2ButtonState: ControlledButtonState {
    mediaPlayer.selectedMedia == Medias.media2 ? .active : .inactive
  }
  private var joinMeetingButtonState: ControlledButtonState {
    meetAddonsManager.addonSessionHasBegun ? .active : .inactive
  }

  var body: some View {
    VStack {
      HStack {
        ControlledButton(
          state: joinMeetingButtonState,
          activeTitle: "Leave Meeting",
          inactiveTitle: "Join Meeting",
          action: meetAddonsManager.addonSessionHasBegun
            ? meetAddonsManager.endAddonSession : meetAddonsManager.beginAddonSession
        )
      }
      HStack {
        ControlledButton(
          state: media1ButtonState, activeTitle: "Media 1 On",
          inactiveTitle: "Media 1 Off"
        ) {
          mediaPlayer.change(to: Medias.media1)
        }
        ControlledButton(
          state: media2ButtonState, activeTitle: "Media 2 On",
          inactiveTitle: "Media 2 Off"
        ) {
          mediaPlayer.change(to: Medias.media2)
        }
        ControlledButton(
          state: .active, activeTitle: "Change Theme",
          inactiveTitle: "", action: appState.switchThemeColor
        )
      }
    }
  }
}

struct ToggleButtonsView_Previews: PreviewProvider {
  static var previews: some View {
    ControlledButtonsView(meetAddonsManager: MeetAddonsManager.shared)
      .environmentObject(AppState.shared)
      .environmentObject(MediaPlayer.shared)
  }
}
