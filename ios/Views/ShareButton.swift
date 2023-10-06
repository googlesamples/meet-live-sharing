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

struct ShareButton: View {
  @EnvironmentObject var appState: AppState
  let meetAddonsManager: MeetAddonsManager = MeetAddonsManager.shared

  @State private var isSharePresented: Bool = false

  var body: some View {
    Button("Share") {
      self.isSharePresented = true
    }
    .buttonStyle(ShareButtonStyle(buttonColor: appState.themeColor))
    .sheet(
      isPresented: $isSharePresented,
      onDismiss: {
        print("Dismiss")
      },
      content: {
        if #available(iOS 16.0, *) {
          ActivityViewController(meetAddonsManager: meetAddonsManager).presentationDetents([
            .medium
          ])
        } else {
          ActivityViewController(meetAddonsManager: meetAddonsManager)
        }
      })
  }
}

struct ActivityViewController: UIViewControllerRepresentable {
  @ObservedObject var meetAddonsManager: MeetAddonsManager

  var applicationActivities: [UIActivity]? = nil

  func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>)
    -> UIActivityViewController
  {
    let controller = UIActivityViewController(
      activityItems: [],
      applicationActivities: [meetAddonsManager.getAddonUIActivity()])
    controller.isModalInPresentation = true
    return controller
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: UIViewControllerRepresentableContext<ActivityViewController>
  ) {}

}

struct ShareButtonView_Previews: PreviewProvider {
  static var previews: some View {
    ShareButton().environmentObject(AppState.shared)
  }
}
