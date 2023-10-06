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

/// View that renders all the logs in a scrollable window.
struct LogWindowView: View {
  @StateObject private var logger: Logger = Logger.shared
  @Namespace var bottomID

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("Log Window")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 10)
      ScrollViewReader { proxy in
        ScrollView(.vertical) {
          VStack(spacing: 8) {
            ForEach(logger.logs, id: \.self) { log in
              Text(log)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.init(top: 0, leading: 10, bottom: 0, trailing: 0))
            }
            Text("")
              .frame(maxWidth: .infinity)
              .id(bottomID)
          }
          .padding(.top, 7)
        }
        .onChange(of: logger.logs) { _ in
          withAnimation {
            proxy.scrollTo(bottomID)
          }
        }
        .foregroundColor(Color.black)
        .font(.system(size: 12))
        .background(Color(UIColor.systemGray4))
        .frame(maxWidth: .infinity)
        .padding(.init(top: 5, leading: 10, bottom: 10, trailing: 10))
      }
    }
  }
}

struct LogWindowView_Previews: PreviewProvider {
  static var previews: some View {
    LogWindowView()
  }
}
