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

/// Possible states of a control button.
public enum ControlledButtonState {
  case disabled
  case inactive
  case active
}

/// A button whose state and appearance are controlled by models within the app.
///
/// Based off of data within the models, the controlled button can either be active, inactive, or
/// disabled.
struct ControlledButton: View {
  @EnvironmentObject var appState: AppState
  public let state: ControlledButtonState
  public let activeTitle: String
  public let inactiveTitle: String
  public let action: () -> Void

  var body: some View {
    Button(state == .active ? activeTitle : inactiveTitle, action: action)
      .buttonStyle(ControlledButtonStyle(themeColor: appState.themeColor, buttonState: state))
      .disabled(state == .disabled)
  }
}

struct ControlledButtonView_Previews: PreviewProvider {
  static var previews: some View {
    ControlledButton(
      state: .active, activeTitle: "On", inactiveTitle: "Off", action: {}
    ).environmentObject(AppState.shared)
    ControlledButton(
      state: .inactive, activeTitle: "On", inactiveTitle: "Off", action: {}
    ).environmentObject(AppState.shared)
    ControlledButton(
      state: .disabled, activeTitle: "On", inactiveTitle: "Off", action: {}
    ).environmentObject(AppState.shared)
  }
}
