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
import MeetAddonsTestAppModels
import SwiftUI

@main
struct TestApp: App {
  @StateObject private var appState: AppState = AppState.shared
  @StateObject private var mediaPlayer: MediaPlayer = MediaPlayer.shared
  private let logger: Logger = Logger.shared
  private let meetAddonsManager: MeetAddonsManager = MeetAddonsManager.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(appState)
        .environmentObject(mediaPlayer)
        .onOpenURL { url in
          logger.log("Opened by Meet app with URL: \(url.absoluteString).")
          meetAddonsManager.beginAddonSession()
        }
    }
  }
}
