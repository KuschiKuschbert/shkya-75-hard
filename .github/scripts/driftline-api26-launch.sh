#!/usr/bin/env bash
set -euo pipefail

APP=/tmp/runtime/Driftline-Echoes-at-0317-v0.4.1.apk
OUT=/tmp/api26-launch-evidence
mkdir -p "$OUT"

adb wait-for-device
adb devices -l | tee "$OUT/adb-devices.txt"
adb shell getprop > "$OUT/device-properties.txt"

timeout 900 adb install -r -t "$APP" > "$OUT/install-app.txt" 2>&1
cat "$OUT/install-app.txt"
grep -q Success "$OUT/install-app.txt"

adb logcat -c >/dev/null 2>&1 || true
timeout 60 adb shell am start -W -S -n "$APP_PACKAGE/$MAIN_ACTIVITY" > "$OUT/first-launch.txt" 2>&1
cat "$OUT/first-launch.txt"
sleep 8
PID="$(adb shell pidof "$APP_PACKAGE" | tr -d '\r')"
test -n "$PID"
echo "$PID" > "$OUT/first-launch.pid"
adb exec-out screencap -p > "$OUT/first-launch.png"
adb shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1 || true
adb pull /sdcard/window.xml "$OUT/first-window.xml" >/dev/null 2>&1 || true
adb logcat -d -v threadtime > "$OUT/logcat-first-launch.txt"
! grep -E "FATAL EXCEPTION|ANR in $APP_PACKAGE|Process: $APP_PACKAGE.*has died" "$OUT/logcat-first-launch.txt"

adb shell am force-stop "$APP_PACKAGE"
sleep 2
adb logcat -c >/dev/null 2>&1 || true
timeout 60 adb shell am start -W -S -n "$APP_PACKAGE/$MAIN_ACTIVITY" > "$OUT/relaunch.txt" 2>&1
cat "$OUT/relaunch.txt"
sleep 6
PID2="$(adb shell pidof "$APP_PACKAGE" | tr -d '\r')"
test -n "$PID2"
echo "$PID2" > "$OUT/relaunch.pid"
adb exec-out screencap -p > "$OUT/relaunch.png"
adb shell uiautomator dump /sdcard/window2.xml >/dev/null 2>&1 || true
adb pull /sdcard/window2.xml "$OUT/relaunch-window.xml" >/dev/null 2>&1 || true
adb logcat -d -v threadtime > "$OUT/logcat-relaunch.txt"
! grep -E "FATAL EXCEPTION|ANR in $APP_PACKAGE|Process: $APP_PACKAGE.*has died" "$OUT/logcat-relaunch.txt"
