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

import android.util.Log;
import androidx.annotation.Nullable;
import com.google.errorprone.annotations.FormatMethod;
import com.google.errorprone.annotations.FormatString;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;
import java.util.concurrent.ArrayBlockingQueue;

/** Logs to a queue. */
final class LogProducer {
  /** Max number of retry attempts used by retry strategy. */
  private static final int TOTAL_RETRY_ATTEMPTS = 3;

  private static final SimpleDateFormat dateFormat =
      new SimpleDateFormat("dd-MMM-yyyy hh:mm:ss aa", Locale.getDefault());

  private final ArrayBlockingQueue<String> logQueue;

  LogProducer(ArrayBlockingQueue<String> logQueue) {
    this.logQueue = logQueue;
  }

  /** Writes a log message to the log queue. */
  @FormatMethod
  public void write(@FormatString String logMessage, @Nullable Object... args) {
    int retryAttempt = 0;
    while (retryAttempt <= TOTAL_RETRY_ATTEMPTS) {
      try {
        String formattedLog =
            dateFormat.format(Calendar.getInstance().getTime())
                + ": "
                + String.format(logMessage, args);
        logQueue.put(formattedLog + "\n\n");
        Log.d("Sample app", formattedLog);
        break;
      } catch (Exception e) {
        Log.e("LogProducer: ", e.toString());
        retryAttempt += 1;
      }
    }
  }

  /** Writes a log message to the log queue. */
  @FormatMethod
  public void write(Throwable throwable, @FormatString String logMessage) {
    int retryAttempt = 0;
    while (retryAttempt <= TOTAL_RETRY_ATTEMPTS) {
      try {
        StringWriter stackTraceWriter = new StringWriter();
        throwable.printStackTrace(new PrintWriter(stackTraceWriter));
        String formattedLog =
            dateFormat.format(Calendar.getInstance().getTime())
                + ": "
                + logMessage
                + ": "
                + throwable
                + "\n"
                + stackTraceWriter;
        logQueue.put(formattedLog + "\n\n");
        Log.d("Sample app", formattedLog);
        break;
      } catch (Exception exception) {
        if (exception instanceof InterruptedException) {
          Thread.currentThread().interrupt();
        }
        Log.e("LogProducer: ", exception.toString());
        retryAttempt += 1;
      }
    }
  }
}
