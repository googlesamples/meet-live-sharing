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

import android.os.Handler;
import android.os.Looper;
import android.widget.TextView;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.logging.Logger;

/** A {@link TextViewContentPublisher} that pulls logs from a queue and publishes them. */
final class LogConsumer implements Runnable, TextViewContentPublisher {
  private static final Logger logger = Logger.getLogger(LogConsumer.class.getName());

  /** Handler to the main thread. */
  private final Handler mainHandler;

  private final ArrayBlockingQueue<String> logQueue;
  private final List<TextView> subscribedTextViews = new ArrayList<>();

  LogConsumer(ArrayBlockingQueue<String> logQueue) {
    this.logQueue = logQueue;
    mainHandler = new Handler(Looper.getMainLooper());
  }

  /**
   * Runs continuously in a separate thread to consume log messages from the log queue and publishes
   * the log message update to subscribers.
   */
  @Override
  public void run() {
    while (true) {
      try {
        String logMessage = logQueue.take();
        notifyUpdate(textView -> mainHandler.post(() -> textView.append(logMessage)));
      } catch (InterruptedException interruptedException) {
        logger.severe(interruptedException.toString());
      }
    }
  }

  @Override
  public void subscribe(TextView textView) {
    subscribedTextViews.add(textView);
  }

  @Override
  public void unsubscribe(TextView textView) {
    subscribedTextViews.remove(textView);
  }

  @Override
  public void notifyUpdate(UpdateNotifier<TextView> updateNotifier) {
    subscribedTextViews.stream().forEach(updateNotifier::notifySubscribers);
  }

  @Override
  public void clearSubscribersList() {
    subscribedTextViews.clear();
  }
}
