#!/usr/bin/env bash
set -euo pipefail

echo "== Android Doctor =="
echo "Java:"; java -version || true
echo "Gradle wrapper:"; (cd android && ./gradlew -v || true)
echo "Flutter:"; flutter --version || true
echo "SDK root: ${ANDROID_SDK_ROOT:-unset}"

# Accept licenses and list current packages
yes | sdkmanager --licenses >/dev/null || true
sdkmanager --list | head -n 40 || true

# Detect compileSdk & AGP
compileSdk=$(grep -E 'compileSdk(?:Version)?\s+[0-9]+' -h android/app/build.gradle* | grep -Eo '[0-9]+' | head -n1 || echo 33)
agp=$(grep -R "com.android.tools.build:gradle" -n android | head -n1 | sed -E 's/.*gradle:([^"]+).*/\1/' || true)
echo "Detected compileSdk=$compileSdk agp=$agp"

# Ensure required SDK components exist
bt="${compileSdk}.0.0"
echo "Installing SDK bits: build-tools;$bt, platforms;android-$compileSdk"
sdkmanager "build-tools;$bt" "platforms;android-$compileSdk" "platform-tools" >/dev/null || true

# Quick dry-run to capture mismatches fast
set +e
(cd android && ./gradlew :app:assembleDebug -m -Dorg.gradle.jvmargs="-Xmx3g" ) &> build-dryrun.log
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "Dry-run flagged issues (top lines):"
  sed -n '1,200p' build-dryrun.log
fi

# If AGP demands a newer Gradle, auto-bump wrapper
need=$(grep -Eo "requires Gradle [0-9]+\.[0-9]+(\.[0-9]+)?" build-dryrun.log | awk '{print $3}' | head -n1 || true)
if [[ -n "$need" ]]; then
  echo "AGP requires Gradle $need — bumping wrapper…"
  file="android/gradle/wrapper/gradle-wrapper.properties"
  sed -E -i.bak "s#distributionUrl=.*#distributionUrl=https\\://services.gradle.org/distributions/gradle-${need}-bin.zip#g" "$file"
  echo "Wrapper bumped to Gradle $need"
fi

# One more attempt: resolve deps only, to surface conflicts
set +e
(cd android && ./gradlew :app:dependencies --configuration releaseRuntimeClasspath -Dorg.gradle.jvmargs="-Xmx3g" ) &> build-deps.log
set -e
echo "Dependency graph captured to build-deps.log"

echo "Android Doctor complete."