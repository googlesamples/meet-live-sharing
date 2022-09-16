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
package com.google.samples.quickstart.livesharing;

import android.widget.TextView;

/** Interface for classes that subscribe {@link TextView}'s to receive updates from a publisher. */
interface TextViewContentPublisher {

  /** Subscribes a {@link TextView} to receive an update. */
  void subscribe(TextView textView);

  /** Unsubscribes a {@link TextView} from receiving updates. */
  void unsubscribe(TextView textView);

  /** Notifies subscribed {@link TextView}'s via an {@link UpdateNotifier}. */
  void notifyUpdate(UpdateNotifier<TextView> notifier);

  /** Clears all subscribers. */
  void clearSubscribersList();
}
