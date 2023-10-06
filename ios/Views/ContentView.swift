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

struct ContentView: View {
  @StateObject private var meetAddonsManager: MeetAddonsManager = MeetAddonsManager.shared
  var body: some View {
    VStack {
      ControlledButtonsView(meetAddonsManager: meetAddonsManager)
      MediaPlayerView()
      ShareButton()
      LogWindowView()
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.top)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .environmentObject(AppState.shared)
      .environmentObject(MediaPlayer.shared)
  }
}
