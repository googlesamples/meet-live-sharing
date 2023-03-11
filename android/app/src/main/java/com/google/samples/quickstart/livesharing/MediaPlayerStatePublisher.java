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
import com.google.errorprone.annotations.CheckReturnValue;
import java.util.ArrayList;
import java.util.List;

/** A {@link TextViewContentPublisher} that publishes {@link MediaPlayer} position updates. */
@CheckReturnValue
final class MediaPlayerStatePublisher implements TextViewContentPublisher {

  private final List<TextView> subscribedTextViews = new ArrayList<>();

  @Override
  public void subscribe(TextView textView) {
    subscribedTextViews.add(textView);
  }

  @Override
  public void unsubscribe(TextView textView) {
    subscribedTextViews.remove(textView);
  }

  @Override
  public void notifyUpdate(UpdateNotifier<TextView> notifier) {
    for (TextView textView : subscribedTextViews) {
      notifier.notifySubscribers(textView);
    }
  }

  @Override
  public void clearSubscribersList() {
    subscribedTextViews.clear();
  }
}
