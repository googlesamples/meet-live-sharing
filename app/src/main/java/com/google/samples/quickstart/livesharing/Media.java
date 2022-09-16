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

import com.google.auto.value.AutoValue;
import com.google.errorprone.annotations.Immutable;
import java.time.Duration;

/** A piece of media that is played by the {@link MediaPlayer}. */
@Immutable
@AutoValue
abstract class Media {
  abstract String id();

  abstract String name();

  abstract Duration duration();

  static Builder builder() {
    return new AutoValue_Media.Builder();
  }

  /** Builder for {@link Media} */
  @AutoValue.Builder
  abstract static class Builder {
    abstract Builder setId(String value);

    abstract Builder setName(String value);

    abstract Builder setDuration(Duration value);

    abstract Media build();
  }
}
