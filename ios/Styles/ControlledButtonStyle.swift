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

/// Custom styling for app control buttons.
struct ControlledButtonStyle: ButtonStyle {
  public var themeColor: Color
  public var buttonState: ControlledButtonState

  private var currentColor: Color {
    switch buttonState {
    case .active:
      return themeColor
    case .inactive:
      return .testAppInactiveButton
    case .disabled:
      return .testAppDisabledButton
    }
  }

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(5)
      .frame(width: 115, height: 60)
      .font(.system(size: 15))
      .foregroundColor(.white)
      .background(currentColor)
      .cornerRadius(10)
      .multilineTextAlignment(.center)
  }
}
