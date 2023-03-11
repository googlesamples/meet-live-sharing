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

public protocol AppStateDelegate: AnyObject {
  func appState(_ appState: AppState, didSwitchColors newColor: Color)
}

/// General state shared throughout the app.
public class AppState: ObservableObject {
  public static let shared: AppState = AppState()

  public weak var delegate: AppStateDelegate?
  @Published public var themeColor: Color = Color.blue

  init() {}

  /// Switches the theme color back and forth between blue and green.
  public func switchThemeColor() {
    themeColor = themeColor == .blue ? .testAppEmerald : .blue
    delegate?.appState(self, didSwitchColors: themeColor)
  }
}

extension Color {
  public static let testAppEmerald: Color = Color(red: 0.0157, green: 0.3882, blue: 0.0275)
  public static let testAppDisabledButton: Color = Color(red: 0.63, green: 0.63, blue: 0.63)
  public static let testAppInactiveButton: Color = Color(red: 0.35, green: 0.35, blue: 0.35)
}
