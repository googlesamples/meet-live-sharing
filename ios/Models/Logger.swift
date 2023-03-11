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

/// Shared logger to be used in other models.
public class Logger: ObservableObject {
  public static let shared: Logger = Logger()

  @Published public var logs: [String] = []

  init() {}

  /// Logs the specified message.
  ///
  /// Logs must be added on the main thread in case this function is called from a separate thead.
  public func log(_ message: String) {
    let formatter: DateFormatter = DateFormatter()
    formatter.dateFormat = "dd-MMM-yyyy hh:mm:ss a"
    let timeStamp: String = formatter.string(from: Date())
    let logMessage: String = "\(timeStamp): \(message)"

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.logs.append(logMessage)
    }
  }
}
