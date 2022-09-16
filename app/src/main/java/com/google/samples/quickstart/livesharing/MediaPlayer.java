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

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.widget.TextView;
import com.google.errorprone.annotations.CheckReturnValue;
import java.time.Duration;
import java.util.Optional;

/** A media player. */
@CheckReturnValue
final class MediaPlayer {

  private static final Duration TIMER_INTERVAL_BETWEEN_TASKS = Duration.ofSeconds(1);

  private final Handler handler = new Handler(Looper.getMainLooper());
  private final MediaPlayerStatePublisher mediaPlayerStatePublisher;
  private final UpdateNotifier<TextView> updateNotifier;

  private Duration length = Duration.ZERO;
  private Duration currentPosition = Duration.ZERO;
  private double playoutRate = 1;
  private State state = State.INACTIVE;
  private Optional<Media> activeMedia = Optional.empty();
  private Optional<Runnable> runnable = Optional.empty();
  private boolean muted = false;

  /** Possible states of the media player. */
  enum State {
    PLAYING,
    PAUSED,
    BUFFERING,
    INACTIVE
  }

  MediaPlayer(Context context) {
    mediaPlayerStatePublisher = new MediaPlayerStatePublisher();
    updateNotifier =
        textView ->
            textView.setText(
                context
                    .getResources()
                    .getString(
                        R.string.textview_timer_running_text,
                        activeMedia.get().name(),
                        currentPosition.getSeconds(),
                        length.getSeconds()));
  }

  /**
   * Registers a {@link Media} for playback.
   *
   * <p>Executes associated UI operations, sets length and active media, etc.
   */
  void registerMediaForPlayback(UiObjectHandler uiObjectHandler, Media media) {
    currentPosition = Duration.ZERO;
    uiObjectHandler.executeUiOperations((int) currentPosition.getSeconds());
    activeMedia = Optional.of(media);
    length = media.duration();
  }

  /**
   * Starts playing current media.
   *
   * <p>Continues playing until the end is reached.
   */
  void startMediaPlayback(UiObjectHandler uiObjectHandler) throws MediaNotActiveException {
    state = State.PLAYING;
    if (!activeMedia.isPresent()) {
      throw new MediaNotActiveException(
          "No active media is selected. Please select media before proceeding with"
              + " play operation.");
    }
    if (!runnable.isPresent()) {
      runnable =
          Optional.of(
              () -> {
                if (hasReachedEndOfMedia()) {
                  try {
                    pauseMediaPlayback(/* simulateBuffering= */ false);
                  } catch (MediaNotActiveException mediaNotActiveException) {
                    Log.e(
                        "Media player error:",
                        "Trying to pause media when it is not active. Getting this exception in"
                            + " this block indicates this is not a normal flow of operations and"
                            + " further needs to be investigated.");
                  }
                  return;
                }
                double positionIncrementMilliSeconds = playoutRate * 1000;
                currentPosition =
                    currentPosition.plus(Duration.ofMillis((long) positionIncrementMilliSeconds));
                uiObjectHandler.executeUiOperations((int) currentPosition.getSeconds());
                mediaPlayerStatePublisher.notifyUpdate(updateNotifier);

                // The runnable should run at every defined interval, hence triggering it here
                // again.
                handler.postDelayed(runnable.get(), TIMER_INTERVAL_BETWEEN_TASKS.toMillis());
              });
    }
    handler.postDelayed(runnable.get(), TIMER_INTERVAL_BETWEEN_TASKS.toMillis());
  }

  /** Returns whether the playback position has reached the media's end. */
  boolean hasReachedEndOfMedia() {
    return currentPosition.compareTo(length) >= 0;
  }

  /** Stops the timer and purges it. */
  private void cancelHandlerRunnableTasks() {
    runnable.ifPresent(handler::removeCallbacks);
  }

  /**
   * Pauses media playback.
   *
   * @param simulateBuffering a flag that sets the media player state to buffering when {@code
   *     true}. In this state, the media player is actually paused internally and only simulating
   *     the buffering scenario.
   */
  void pauseMediaPlayback(boolean simulateBuffering) throws MediaNotActiveException {
    if (!activeMedia.isPresent()) {
      throw new MediaNotActiveException(
          "No active media is selected. Please select media before proceeding with pause"
              + " operation.");
    }
    if (simulateBuffering) {
      state = State.BUFFERING;
    } else {
      state = State.PAUSED;
    }
    cancelHandlerRunnableTasks();
  }

  /**
   * Stops media playback.
   *
   * <p>As a consequence, all the subscribed {@link TextView}'s will be unsubscribed from receiving
   * further playback position updates.
   */
  void stopMediaPlayback(UiObjectHandler uiObjectHandler) throws MediaNotActiveException {
    if (!activeMedia.isPresent()) {
      throw new MediaNotActiveException(
          "No active media is selected. Please select media before attempting to stop media"
              + " playback.");
    }
    cancelHandlerRunnableTasks();
    currentPosition = Duration.ZERO;
    uiObjectHandler.executeUiOperations((int) currentPosition.getSeconds());
    state = State.INACTIVE;
    activeMedia = Optional.empty();
    mediaPlayerStatePublisher.clearSubscribersList();
  }

  /** Returns whether media is currently active (selected on UI) or not. */
  boolean isActive() {
    return state != State.INACTIVE;
  }

  /** Returns whether the media is playing. */
  boolean isPlaying() {
    return state == State.PLAYING;
  }

  /** Returns whether the media is paused. */
  boolean isPaused() {
    return state == State.PAUSED;
  }

  /** Returns whether the media is paused. */
  boolean isBuffering() {
    return state == State.BUFFERING;
  }

  /** Returns the current media state. */
  State getState() {
    return state;
  }

  /** Returns the active media. */
  Optional<Media> getActiveMedia() {
    return activeMedia;
  }

  /** Sets the current position of media player. */
  void setCurrentPosition(Duration position) {
    currentPosition = position;
  }

  /** Returns the current position of the media player. */
  Duration getCurrentPosition() {
    return currentPosition;
  }

  /** Returns the media playout rate. */
  double getPlayoutRate() {
    return playoutRate;
  }

  /** Sets the media play rate. */
  void setPlayoutRate(double playoutRate) {
    this.playoutRate = playoutRate;
  }

  /** Returns whether the media player is muted. */
  boolean isMuted() {
    return muted;
  }

  /** Sets whether the media player is muted. */
  void setMuted(boolean mutedState) {
    muted = mutedState;
  }

  MediaPlayerStatePublisher getStatePublisher() {
    return mediaPlayerStatePublisher;
  }
}
