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

/// A type that contains relevant info for a media instance.
public struct Media: Equatable {
  public let name: String
  public let duration: TimeInterval
}

/// Possible medias that the app media player can be switched to.
public enum Medias {
  public static let media1: Media = Media(name: "media_1", duration: 100)
  public static let media2: Media = Media(name: "media_2", duration: 10)
  private static let medias: [Media] = [media1, media2]
  /// Gets a media by name if it exists.
  public static func getMedia(mediaName: String) -> Media? {
    return medias.first { $0.name == mediaName }
  }
}
