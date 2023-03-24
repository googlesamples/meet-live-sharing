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

import static com.google.common.util.concurrent.Futures.addCallback;
import static com.google.common.util.concurrent.MoreExecutors.directExecutor;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.os.Bundle;
import android.text.method.ScrollingMovementMethod;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;
import android.widget.Spinner;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.livesharing.CoDoingSession;
import com.google.android.livesharing.CoDoingSessionDelegate;
import com.google.android.livesharing.CoDoingState;
import com.google.android.livesharing.CoWatchingSession;
import com.google.android.livesharing.CoWatchingSessionDelegate;
import com.google.android.livesharing.CoWatchingState;
import com.google.android.livesharing.LiveSharingClient;
import com.google.android.livesharing.LiveSharingClientFactory;
import com.google.android.livesharing.LiveSharingMeetingInfo;
import com.google.android.livesharing.LiveSharingSession;
import com.google.android.livesharing.LiveSharingSessionDelegate;
import com.google.android.livesharing.ParticipantMetadataDelegate;
import com.google.android.livesharing.QueriedCoWatchingState;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.protobuf.ByteString;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.function.Consumer;
import java.util.function.UnaryOperator;

/** Serves as the launch point for the app. */
public final class MainActivity extends AppCompatActivity
    implements CoWatchingSessionDelegate,
        CoDoingSessionDelegate,
        ParticipantMetadataDelegate,
        LiveSharingSessionDelegate {

  private enum SessionType {
    NONE,
    CO_WATCHING,
    CO_DOING,
    BOTH
  }

  // Predefined lengths for two media objects.
  private static final Duration MEDIA_1_LENGTH = Duration.ofSeconds(100);
  private static final Duration MEDIA_2_LENGTH = Duration.ofSeconds(10);

  /** Max queue length for the log queue. */
  private static final int MAX_QUEUE_LENGTH = 1000;

  /** Playout rate values used in the playout rate selection spinner. */
  private static final ImmutableList<Double> PLAYOUT_RATE_RAW_VALUES =
      ImmutableList.of(0.5, 1.0, 1.25, 1.5, 1.75, 2.0);

  /** A sample participant metadata that will be set on behalf of the user. */
  private static final String PARTICIPANT_METADATA = "participant_metadata";

  private final ArrayBlockingQueue<String> logQueue = new ArrayBlockingQueue<>(MAX_QUEUE_LENGTH);

  // Media objects. We are using following two predefined media objects and won't be creating them
  // on the fly as dynamic creation of media objects is not really required at this stage to test
  // co-watching APIs through testapp.
  private final Media media1 =
      Media.builder().setId("media_1").setName("Media 1").setDuration(MEDIA_1_LENGTH).build();
  private final Media media2 =
      Media.builder().setId("media_2").setName("Media 2").setDuration(MEDIA_2_LENGTH).build();

  /** Map to store mapping between a media object and corresponding toggle button on screen. */
  private final Map<Media, ToggleButton> mediaBtnMap = new HashMap<>();

  /** Map to store mapping between a media id and corresponding media object. */
  private final ImmutableMap<String, Media> mediaMap =
      new ImmutableMap.Builder<String, Media>()
          .put(media1.id(), media1)
          .put(media2.id(), media2)
          .buildOrThrow();

  private Button btnStartCoWatching;
  private Button btnStartCoDoing;
  private Button btnStartBoth;
  private Button btnEndSession;

  // Toggle buttons used to select which media to play.
  private ToggleButton toggleBtnMedia1;
  private ToggleButton toggleBtnMedia2;

  // Buttons to control media play/pause.
  private Button btnPlay;
  private Button btnPause;

  /** Button to set participant metadata in a live sharing session. */
  private Button btnSetMetadata;

  /** Button to check for ongoing Meet and/or live sharing session. */
  private Button btnOnGoingActivityCheck;

  /** Text view showing current media position. */
  private TextView textViewTimer;

  /** Text view that displays live logs. */
  private TextView textViewLogWindow;

  /** Switch used to change background color. */
  private Switch switchBackgroundColorChange;

  /** Text view that displays meeting status. */
  private TextView textViewMeetingStatus;

  /** Slider to move media's position. */
  private SeekBar seekBarMedia;

  /** Spinner to change media playout rate. */
  private Spinner spinnerPlayoutRates;

  /**
   * Flag used to determine if {@code onSelectedListener} is triggered by a user or the program
   * itself as a side effect of call to {@code setSelection}.
   */
  private boolean onItemSelectedListenerTriggeredByUser = true;

  private MediaPlayer mediaPlayer;

  private LogConsumer logConsumer;
  private LogProducer logProducer;

  private final LiveSharingClient liveSharingClient = LiveSharingClientFactory.getClient();
  private volatile Optional<LiveSharingMeetingInfo> liveSharingMeetingInfo = Optional.empty();
  private Optional<LiveSharingSession> session = Optional.empty();
  private SessionType sessionType = SessionType.NONE;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.main_activity);
    initializeUiElements();
    initializeInternalLogging();
    setOnClickListeners();
    mediaPlayer = new MediaPlayer(this);
    mediaBtnMap.put(media1, toggleBtnMedia1);
    mediaBtnMap.put(media2, toggleBtnMedia2);
    getSupportActionBar().hide();
  }

  /** Initializes UI elements such as buttons, switches etc. */
  private void initializeUiElements() {
    btnStartCoWatching = findViewById(R.id.button_start_cowatching);
    btnStartCoDoing = findViewById(R.id.button_start_codoing);
    btnStartBoth = findViewById(R.id.button_start_both);
    btnEndSession = findViewById(R.id.button_end_session);
    textViewLogWindow = findViewById(R.id.textview_logwindow);
    textViewLogWindow.setMovementMethod(new ScrollingMovementMethod());
    textViewMeetingStatus = findViewById(R.id.textview_meeting_status);
    toggleBtnMedia1 = findViewById(R.id.togglebutton_media1);
    toggleBtnMedia2 = findViewById(R.id.togglebutton_media2);
    switchBackgroundColorChange = findViewById(R.id.switch_bgcolorchange);
    textViewTimer = findViewById(R.id.textview_timer);
    btnPlay = findViewById(R.id.button_play);
    btnPause = findViewById(R.id.button_pause);
    btnSetMetadata = findViewById(R.id.button_set_metadata);
    btnOnGoingActivityCheck = findViewById(R.id.button_ongoing_activity_check);
    seekBarMedia = findViewById(R.id.seekbar_media);
    spinnerPlayoutRates = (Spinner) findViewById(R.id.spinner_playoutrate);
    String[] dropdownValues = new String[PLAYOUT_RATE_RAW_VALUES.size()];
    for (int i = 0; i < PLAYOUT_RATE_RAW_VALUES.size(); i++) {
      dropdownValues[i] = PLAYOUT_RATE_RAW_VALUES.get(i) + "x";
    }
    // Create an ArrayAdapter using the string array and a default spinner layout
    ArrayAdapter<String> adapter =
        new ArrayAdapter<>(
            /* Context= */ this, android.R.layout.simple_spinner_dropdown_item, dropdownValues);

    // Specify the layout to use when the list of choices appears
    adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
    // Apply the adapter to the spinner
    spinnerPlayoutRates.setAdapter(adapter);
    // Set default selection for playout rate.
    spinnerPlayoutRates.setSelection(adapter.getPosition("1.0x"));
  }

  /** Initializes the {@link LogConsumer}. */
  private void initializeInternalLogging() {
    logConsumer = new LogConsumer(logQueue);
    logConsumer.subscribe(textViewLogWindow);
    new Thread(logConsumer).start();
    logProducer = new LogProducer(logQueue);
  }

  /** Sets {@code onClick} listeners for various UI components. */
  private void setOnClickListeners() {
    btnStartCoWatching.setOnClickListener(this::handleStartCoWatchingClick);
    btnStartCoDoing.setOnClickListener(this::handleStartCoDoingClick);
    btnStartBoth.setOnClickListener(this::handleStartBothClick);
    btnEndSession.setOnClickListener(this::handleEndSessionClick);
    btnPlay.setOnClickListener(this::handlePlayBtnClick);
    btnPause.setOnClickListener(this::handlePauseBtnClick);
    btnSetMetadata.setOnClickListener(this::handleSetMetadataBtnClick);
    btnOnGoingActivityCheck.setOnClickListener(this::handleOngoingBtnClick);
    switchBackgroundColorChange.setOnCheckedChangeListener(
        this::handleBackgroundColorChangeSwitchOnCheckedChange);
    toggleBtnMedia1.setOnClickListener((view) -> handleMediaBtnOnClick(view, media1));
    toggleBtnMedia2.setOnClickListener((view) -> handleMediaBtnOnClick(view, media2));
    seekBarMedia.setOnSeekBarChangeListener(
        new OnSeekBarChangeListener() {
          @Override
          public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
            if (fromUser) {
              Duration seekDuration = Duration.ofSeconds(progress);
              mediaPlayer.setCurrentPosition(seekDuration);
              maybeUpdateCoWatching(coWatching -> coWatching.notifySeekToTimestamp(seekDuration));
            }
          }

          @Override
          public void onStartTrackingTouch(SeekBar seekBar) {}

          @Override
          public void onStopTrackingTouch(SeekBar seekBar) {}
        });

    spinnerPlayoutRates.setOnItemSelectedListener(
        new AdapterView.OnItemSelectedListener() {
          @Override
          public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
            // If triggered by the program itself as a side effect of call to setSelection method,
            // do not proceed as in this case the intention is to only set the selection and not
            // trigger associated listener.
            if (!onItemSelectedListenerTriggeredByUser) {
              onItemSelectedListenerTriggeredByUser = true;
              return;
            }
            mediaPlayer.setPlayoutRate(PLAYOUT_RATE_RAW_VALUES.get(position));
            maybeUpdateCoWatching(
                coWatching ->
                    coWatching.notifyPlayoutRate(
                        PLAYOUT_RATE_RAW_VALUES.get(position), mediaPlayer.getCurrentPosition()));
          }

          @Override
          public void onNothingSelected(AdapterView<?> parent) {}
        });

    textViewLogWindow.setOnLongClickListener(
        (view) -> {
          ClipboardManager clipboard = (ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
          clipboard.setPrimaryClip(ClipData.newPlainText("logText", textViewLogWindow.getText()));
          Toast.makeText(
                  getApplicationContext(), "Log text copied to clipboard.", Toast.LENGTH_SHORT)
              .show();
          return true;
        });
  }

  /** Handles media play & stop scenarios based on the toggle state. */
  private void handleMediaBtnOnClick(View view, Media media) {
    stopMediaPlayback(/* broadcastUpdate= */ true);
    if (((ToggleButton) view).isChecked()) {
      try {
        registerMediaForPlayback(this, media.id(), /* broadcastUpdate= */ true);
      } catch (MediaNotFoundException mediaNotFoundException) {
        Toast.makeText(this, mediaNotFoundException.toString(), Toast.LENGTH_SHORT).show();
      }
    }
  }

  private void handleOngoingBtnClick(View view) {
    ListenableFuture<LiveSharingMeetingInfo> meetingInfo =
        liveSharingClient.queryMeeting(getApplicationContext(), /* handler= */ Optional.empty());

    addCallback(
        meetingInfo,
        new FutureCallback<LiveSharingMeetingInfo>() {
          @Override
          public void onSuccess(LiveSharingMeetingInfo info) {
            logProducer.write("Current Meet LiveSharing status: %s", info.meetingStatus().name());
            runOnUiThread(() -> textViewMeetingStatus.setText(info.meetingStatus().name()));
          }

          @Override
          public void onFailure(Throwable throwable) {
            logProducer.write(throwable, "Failed to resolve any ongoing session information");
          }
        },
        directExecutor());
  }

  /**
   * Performs tasks required when stopping media playback.
   *
   * @param broadcastUpdate a flag that determines whether the new media playback state should be
   *     broadcasted to co-watching session or not. For example, in case this method is triggered by
   *     the co-watching callback, it should not broadacast it again.
   */
  private void stopMediaPlayback(boolean broadcastUpdate) {
    Optional<Media> activeMedia = mediaPlayer.getActiveMedia();
    if (!activeMedia.isPresent()) {
      return;
    }
    try {
      Duration currentPosition = mediaPlayer.getCurrentPosition();
      mediaPlayer.stopMediaPlayback(
          seekBarPosition ->
              runOnUiThread(
                  () -> {
                    seekBarMedia.setProgress(seekBarPosition);
                    if (mediaBtnMap.containsKey(activeMedia.get())) {
                      mediaBtnMap.get(activeMedia.get()).setChecked(false);
                    } else {
                      Toast.makeText(
                              getApplicationContext(),
                              "No associated button for this media was found on UI. Please make"
                                  + " sure all media objects have associated UI buttons before"
                                  + " running the app.",
                              Toast.LENGTH_LONG)
                          .show();
                    }
                  }));
      if (broadcastUpdate) {
        maybeUpdateCoWatching(coWatching -> coWatching.notifyEnded(currentPosition));
      }
    } catch (MediaNotActiveException mediaNotActiveException) {
      Toast.makeText(this, mediaNotActiveException.toString(), Toast.LENGTH_SHORT).show();
    }
    runOnUiThread(
        () ->
            textViewTimer.setText(
                this.getResources().getString(R.string.textview_timer_placeholder_text)));
  }

  /**
   * Performs tasks required for media playback registration.
   *
   * @param context current application context.
   * @param mediaId the ID associated with the media that needs to be registered.
   * @param broadcastUpdate a flag that determines whether the new media playback state should be
   *     broadcasted to co-watching session or not. For example, in case this method is triggered by
   *     the co-watching callback, it should not broadacast it again.
   */
  private void registerMediaForPlayback(Context context, String mediaId, boolean broadcastUpdate)
      throws MediaNotFoundException {
    if (!mediaMap.containsKey(mediaId)) {
      throw new MediaNotFoundException("Media with Id: " + mediaId + " not found.");
    }
    Media media = mediaMap.get(mediaId);
    mediaPlayer.registerMediaForPlayback(
        seekBarPosition ->
            runOnUiThread(
                () -> {
                  seekBarMedia.setProgress(seekBarPosition);
                  mediaBtnMap.get(media).setChecked(true);
                  textViewTimer.setText(
                      context.getResources().getString(R.string.media_selection_message));
                  seekBarMedia.setMax((int) media.duration().getSeconds());
                }),
        media);
    mediaPlayer.getStatePublisher().subscribe(textViewTimer);
    startMediaPlayback();
    if (broadcastUpdate) {
      maybeUpdateCoWatching(
          coWatching ->
              coWatching.notifySwitchedToMedia(
                  media.name(), mediaId, /* mediaPlayoutPosition= */ Duration.ZERO));
    }
  }

  /** Handles "start co-watching" button click. */
  public void handleStartCoWatchingClick(View view) {
    beginCoWatching();
  }

  /** Handles "start co-doing" button click. */
  public void handleStartCoDoingClick(View view) {
    beginCoDoing();
  }

  /** Handles "start both" button click. */
  public void handleStartBothClick(View view) {
    beginCoWatchingAndDoing();
  }

  /** Handles "start both" button click. */
  public void handleEndSessionClick(View view) {
    leaveMeeting();
  }

  /** Handles play button click */
  public void handlePlayBtnClick(View view) {
    if (!mediaPlayer.getActiveMedia().isPresent()) {
      Toast.makeText(this, "No media is playing.", Toast.LENGTH_SHORT).show();
      return;
    }
    if (mediaPlayer.isPlaying()) {
      Toast.makeText(this, "Media is already playing.", Toast.LENGTH_SHORT).show();
      return;
    }
    if (mediaPlayer.isBuffering()) {
      Toast.makeText(this, "Media is buffering...please wait", Toast.LENGTH_SHORT).show();
      return;
    }
    if (mediaPlayer.hasReachedEndOfMedia()) {
      Toast.makeText(this, "Media has reached the end of play.", Toast.LENGTH_SHORT).show();
      return;
    }
    Toast.makeText(this, "Playing Media.", Toast.LENGTH_SHORT).show();
    startMediaPlayback();
    maybeUpdateCoWatching(
        coWatching ->
            coWatching.notifyPauseState(/* paused= */ false, mediaPlayer.getCurrentPosition()));
  }

  private void startMediaPlayback() {
    try {
      mediaPlayer.startMediaPlayback(
          seekBarProgress -> runOnUiThread(() -> seekBarMedia.setProgress(seekBarProgress)));
    } catch (MediaNotActiveException mediaNotActiveException) {
      Toast.makeText(this, mediaNotActiveException.toString(), Toast.LENGTH_SHORT).show();
    }
  }

  /** Wraps {@link MediaPlayer#pauseMediaPlayback} with exception handling. */
  private void pauseMediaPlayback(boolean simulateBuffering) {
    try {
      mediaPlayer.pauseMediaPlayback(simulateBuffering);
    } catch (MediaNotActiveException mediaNotActiveException) {
      Toast.makeText(this, mediaNotActiveException.toString(), Toast.LENGTH_SHORT).show();
    }
  }

  /** Handles a pause button click. */
  public void handlePauseBtnClick(View view) {
    if (!mediaPlayer.getActiveMedia().isPresent()) {
      Toast.makeText(this, "No media is playing.", Toast.LENGTH_SHORT).show();
      return;
    }
    if (mediaPlayer.isPaused()) {
      Toast.makeText(this, "Media is already paused.", Toast.LENGTH_SHORT).show();
      return;
    }
    if (!(mediaPlayer.isPlaying() || mediaPlayer.isBuffering())) {
      Toast.makeText(this, "Media is not yet playing.", Toast.LENGTH_SHORT).show();
      return;
    }
    Toast.makeText(this, "Pausing Media.", Toast.LENGTH_SHORT).show();
    pauseMediaPlayback(/* simulateBuffering= */ false);
    maybeUpdateCoWatching(
        coWatching ->
            coWatching.notifyPauseState(/* paused= */ true, mediaPlayer.getCurrentPosition()));
  }

  /** Handles "set metadata" button click. */
  public void handleSetMetadataBtnClick(View view) {
    session.ifPresent(
        session -> {
          try {
            session.updateParticipantMetadata(PARTICIPANT_METADATA.getBytes());
            logProducer.write("#setParticipantMetadata: setting sample participant metadata.");
          } catch (IllegalStateException | IllegalArgumentException e) {
            logProducer.write("#setParticipantMetadata failed with error: %s", e);
          }
        });
  }

  /** Handles a background color toggle change. */
  private void handleBackgroundColorChangeSwitchOnCheckedChange(
      CompoundButton btn, boolean isChecked) {
    if (isChecked) {
      btn.getRootView()
          .setBackgroundColor(getResources().getColor(android.R.color.holo_orange_light));
    } else {
      btn.getRootView().setBackgroundColor(getResources().getColor(android.R.color.white));
    }

    // Only broadcast update if the user has manually pressed the background change button.
    if (btn.isPressed()) {
      logProducer.write("Broadcasting new coDoing state %s with CoDoing#setGlobalState", isChecked);
      maybeUpdateCoDoing(
          coDoing ->
              coDoing.setGlobalState(
                  CoDoingState.builder()
                      .setState(ByteString.copyFromUtf8(String.valueOf(isChecked)).toByteArray())
                      .build()));
    }
  }

  private void beginCoWatching() {
    beginSession(
        builder -> builder.withCoWatching(/* coWatchingDelegate= */ this), SessionType.CO_WATCHING);
  }

  private void beginCoDoing() {
    beginSession(builder -> builder.withCoDoing(/* coDoingDelegate= */ this), SessionType.CO_DOING);
  }

  private void beginCoWatchingAndDoing() {
    beginSession(
        builder ->
            builder
                .withCoWatching(/* coWatchingDelegate= */ this)
                .withCoDoing(/* coDoingDelegate= */ this),
        SessionType.BOTH);
  }

  private void beginSession(
      UnaryOperator<LiveSharingSession.Builder> setUpSessionFn, SessionType type) {
    if (session.isPresent()) {
      Toast.makeText(this, "A session is already in progress.", Toast.LENGTH_SHORT).show();
      return;
    }

    LiveSharingSession.Builder builder =
        liveSharingClient
            .newSessionBuilder(
                /* liveSharingApplicationName= */ "testApp", /* sessionDelegate= */ this)
            .withParticipantMetadata(/* metadataDelegate= */ this);

    logProducer.write("Calling LiveSharingSession.Builder#begin.");

    addCallback(
        setUpSessionFn.apply(builder).begin(getApplicationContext()),
        new FutureCallback<LiveSharingSession>() {
          @Override
          public void onSuccess(LiveSharingSession result) {
            session = Optional.of(result);
            LiveSharingMeetingInfo meetingInfo = result.getMeetingInfo();
            logProducer.write(
                "LiveSharingSession.Builder#begin: session creation successful; Meeting Code: %s,"
                    + " Meeting URL: %s, Meeting status: %s",
                meetingInfo.meetingCode(), meetingInfo.meetingUrl(), meetingInfo.meetingStatus());
            setStartButtonsVisible(/* visible= */ false);
            liveSharingMeetingInfo = Optional.of(meetingInfo);
            sessionType = type;
          }

          @Override
          public void onFailure(Throwable t) {
            logProducer.write("LiveSharingSession.Builder#begin: Failed to begin session.");
            setStartButtonsVisible(/* visible= */ true);
          }
        },
        directExecutor());
  }

  private void setStartButtonsVisible(boolean visible) {
    runOnUiThread(
        () -> {
          btnStartCoWatching.setVisibility(visible ? View.VISIBLE : View.INVISIBLE);
          btnStartCoDoing.setVisibility(visible ? View.VISIBLE : View.INVISIBLE);
          btnStartBoth.setVisibility(visible ? View.VISIBLE : View.INVISIBLE);
          btnEndSession.setVisibility(!visible ? View.VISIBLE : View.INVISIBLE);
        });
  }

  /** Leaves the Google Meet meeting. */
  private void leaveMeeting() {
    logProducer.write("Calling LiveSharingSession#endSession.");
    session.ifPresent(
        activeSession ->
            addCallback(
                activeSession.endSession(),
                new FutureCallback<Void>() {
                  @Override
                  public void onSuccess(Void result) {
                    logProducer.write("Ended session.");
                    setStartButtonsVisible(/* visible= */ true);
                    session = Optional.empty();
                    sessionType = SessionType.NONE;
                  }

                  @Override
                  public void onFailure(Throwable t) {
                    logProducer.write("Error while ending session: %s", t.getMessage());
                  }
                },
                directExecutor()));
  }

  /** Applies co-watching state to the media player. */
  @Override
  public void onCoWatchingStateChanged(CoWatchingState coWatchingState) {
    logProducer.write(
        "CoWatchingSessionDelegate#onCoWatchingStateChanged: callback method called by SDK.");

    logProducer.write(
        "Received CoWatchingState: %s, with position:%s",
        coWatchingState, coWatchingState.mediaPlayoutPosition().getSeconds());

    try {
      handleMediaRegistrationUpdate(coWatchingState.mediaId());
    } catch (MediaNotFoundException mediaNotFoundException) {
      logProducer.write("CoWatchingSessionDelegate: %s", mediaNotFoundException.toString());
      return;
    }

    if (mediaPlayer.getPlayoutRate() != coWatchingState.mediaPlayoutRate()) {
      logProducer.write(
          "CoWatchingSessionDelegate#onCoWatchingStateChanged: Changing playout rate to: %s",
          coWatchingState.mediaPlayoutRate());
      mediaPlayer.setPlayoutRate(coWatchingState.mediaPlayoutRate());
      int playoutRatePosition = PLAYOUT_RATE_RAW_VALUES.indexOf(coWatchingState.mediaPlayoutRate());
      if (playoutRatePosition != -1) {
        onItemSelectedListenerTriggeredByUser = false;
        runOnUiThread(() -> spinnerPlayoutRates.setSelection(playoutRatePosition));
      } else {
        logProducer.write(
            "Could not find playout rate %s in available playout rates.",
            coWatchingState.mediaPlayoutRate());
      }
    }

    if (!mediaPlayer.getCurrentPosition().equals(coWatchingState.mediaPlayoutPosition())) {
      logProducer.write(
          "CoWatchingSessionDelegate#onCoWatchingStateChanged: Changing playout position to: %s",
          coWatchingState.mediaPlayoutPosition().getSeconds());
      mediaPlayer.setCurrentPosition(coWatchingState.mediaPlayoutPosition());
    }

    handlePlaybackStateUpdates(coWatchingState.playbackState());
  }

  /**
   * Takes appropriate media registration action based on received media information.
   *
   * @param mediaId ID of media that is currently playing.
   */
  private void handleMediaRegistrationUpdate(String mediaId) throws MediaNotFoundException {
    boolean mediaRegistrationRequired = true;

    if (mediaPlayer.getActiveMedia().isPresent()) {
      Media activeMedia = mediaPlayer.getActiveMedia().get();
      if (activeMedia.id().equals(mediaId)) {
        mediaRegistrationRequired = false;
      } else {
        runOnUiThread(() -> mediaBtnMap.get(activeMedia).setChecked(false));
        logProducer.write("handleMediaRegistrationUpdate: Stopping existing media" + " playback.");
        stopMediaPlayback(/* broadcastUpdate= */ false);
      }
    }

    if (mediaRegistrationRequired) {
      logProducer.write(
          "handleMediaRegistrationUpdate: Registering new media for playback" + " with ID %s",
          mediaId);
      registerMediaForPlayback(this, mediaId, /* broadcastUpdate= */ false);
      runOnUiThread(() -> mediaBtnMap.get(mediaPlayer.getActiveMedia().get()).setChecked(true));
    }
  }

  /**
   * Takes appropriate media playback action based on received playback state
   *
   * @param playbackState the current state of media playback.
   */
  private void handlePlaybackStateUpdates(CoWatchingState.PlaybackState playbackState) {
    switch (playbackState) {
      case PLAY:
        if (!mediaPlayer.isPlaying()) {
          logProducer.write("handlePlaybackStateUpdates: Starting media playback.");
          startMediaPlayback();
        }
        break;
      case PAUSE:
        if (!mediaPlayer.isPaused()) {
          logProducer.write("handlePlaybackStateUpdates: Pausing media.");
          pauseMediaPlayback(/* simulateBuffering= */ false);
        }
        break;
      case BUFFERING:
        if (!mediaPlayer.isBuffering()) {
          logProducer.write("handlePlaybackStateUpdates: Buffering media.");
          pauseMediaPlayback(/* simulateBuffering= */ true);
        }
        break;
      case ENDED:
        logProducer.write("handlePlaybackStateUpdates: Ended media playback.");
        stopMediaPlayback(/* broadcastUpdate= */ false);
        break;
    }
  }

  private void maybeUpdateCoWatching(Consumer<CoWatchingSession> notifyFn) {
    if (!(sessionType.equals(SessionType.CO_WATCHING) || sessionType.equals(SessionType.BOTH))) {
      logProducer.write("Skipped updating co-watching: wrong session type.");
      return;
    }
    session.ifPresent(session -> notifyFn.accept(session.getCoWatching()));
  }

  private void maybeUpdateCoDoing(Consumer<CoDoingSession> notifyFn) {
    if (!(sessionType.equals(SessionType.CO_DOING) || sessionType.equals(SessionType.BOTH))) {
      logProducer.write("Skipped updating co-doing: wrong session type.");
      return;
    }
    session.ifPresent(session -> notifyFn.accept(session.getCoDoing()));
  }

  /** Returns co-watching state based on the current media player state. */
  @Override
  public Optional<QueriedCoWatchingState> onStateQuery() {
    if (!session.isPresent()) {
      return Optional.empty();
    }

    Duration position = mediaPlayer.getCurrentPosition();
    logProducer.write("CoWatchingSessionDelegate#onCoWatchingStateQuery: %s", position);
    return Optional.of(() -> position);
  }

  /** Applies co-doing state. */
  @Override
  public void onGlobalStateChanged(CoDoingState coDoingState) {
    logProducer.write(
        "CoDoingSessionDelegate#onCoDoingStateChanged: callback method called by SDK.");
    try {
      String coDoingStateString = ByteString.copyFrom(coDoingState.state()).toStringUtf8();
      logProducer.write(
          "CoDoingSessionDelegate#onCoDoingStateChanged: coDoingState value: %s",
          coDoingStateString);
      boolean checkedState = Boolean.parseBoolean(coDoingStateString);
      runOnUiThread(() -> switchBackgroundColorChange.setChecked(checkedState));
    } catch (RuntimeException exception) {
      logProducer.write(
          "CoDoingSessionDelegate#onCoDoingStateChanged: got exception: %s", exception.toString());
    }
  }

  @Override
  public void onParticipantMetadataUpdated(Set<Byte[]> allParticipantMetadata) {
    logProducer.write("#onParticipantMetadataChanged: %s", allParticipantMetadata);
  }

  /** Handles the end of a session. */
  @Override
  public void onSessionEnded(EndReason endReason) {
    if (!liveSharingMeetingInfo.isPresent()) {
      logProducer.write(
          "onMeetingEnded: LiveSharingMeetingInfo is absent indicating joinMeeting was"
              + " not successful. Please try to rejoin the meeting.");
      return;
    }

    switch (endReason) {
      case SESSION_ENDED_BY_USER:
        logProducer.write("LiveSharingSessionDelegate#onMeetingEnded: session ended.");
        break;
      case MEETING_ENDED_BY_USER:
        logProducer.write("LiveSharingSessionDelegate#onMeetingEnded: meeting ended.");
        break;
      case SESSION_ENDED_UNEXPECTEDLY:
        logProducer.write("LiveSharingSessionDelegate#onMeetingEnded: meeting crashed.");
    }

    // Cleanup state to reflect no longer connected to Meeting
    setStartButtonsVisible(/* visible= */ true);
    session = Optional.empty();
    sessionType = SessionType.NONE;
    liveSharingMeetingInfo = Optional.empty();
  }
}
