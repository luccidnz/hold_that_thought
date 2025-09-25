#!/usr/bin/env bash
set -eu

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

retry() {
  local cmd="$1"; local max="${2:-12}"; local sleep_s="${3:-10}"; local n=0
  until eval "$cmd"; do
    n=$((n+1))
    if [ "$n" -ge "$max" ]; then log "retry: giving up: $cmd"; return 1; fi
    log "retry $n: $cmd"
    sleep "$sleep_s"
  done
}

wait_for_pm() {
  log "waiting for Package Manager + dependent services…"
  # up to ~8 min: 96 * 5s
  for i in $(seq 1 96); do
    # Check multiple readiness criteria
    PM_READY=0
    STORAGE_READY=0
    SETTINGS_READY=0
    
    # Package Manager basic availability
    if adb shell 'cmd package list packages >/dev/null 2>&1' && adb shell pm path android 2>/dev/null | grep -q '^package:'; then
      PM_READY=1
    fi
    
    # Storage Manager readiness (avoid NullPointerException on getVolumes)
    if adb shell 'vdc volume list' >/dev/null 2>&1; then
      STORAGE_READY=1
    fi
    
    # Settings provider readiness (avoid IllegalStateException on system providers)
    if adb shell 'settings get global device_provisioned' >/dev/null 2>&1; then
      SETTINGS_READY=1
    fi
    
    if [ "$PM_READY" = "1" ] && [ "$STORAGE_READY" = "1" ] && [ "$SETTINGS_READY" = "1" ]; then
      log "All installation services ready (PM=$PM_READY storage=$STORAGE_READY settings=$SETTINGS_READY)"
      return 0
    fi
    
    # heal adb transport every ~60s  
    if [ $((i % 12)) -eq 0 ]; then
      log "Service check $i/96: PM=$PM_READY storage=$STORAGE_READY settings=$SETTINGS_READY (healing adb)"
      adb kill-server || true
      adb start-server || true
      adb wait-for-device || true
    fi
    sleep 5
  done
  log "Installation services were not ready in time (PM=$PM_READY storage=$STORAGE_READY settings=$SETTINGS_READY)"
  return 1
}

log "adb prep"
adb kill-server || true
adb start-server || true
adb version || true
retry "adb wait-for-device"

log "deep boot wait"
BOOT_OK=0
for _ in $(seq 1 48); do  # ~8 min
  A=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  B=$(adb shell getprop dev.bootcomplete 2>/dev/null | tr -d '\r')
  C=$(adb shell getprop sys.user.0.running 2>/dev/null | tr -d '\r')
  D=$(adb shell settings get global device_provisioned 2>/dev/null | tr -d '\r')
  if [ "$A" = "1" ] || [ "$B" = "1" ] || { [ "$C" = "1" ] && [ "$D" = "1" ]; }; then
    log "boot: sys.boot_completed=$A dev.bootcomplete=$B user0=$C provisioned=$D"
    BOOT_OK=1; break
  fi
  adb kill-server || true
  adb start-server || true
  sleep 10
done
[ "$BOOT_OK" = "1" ] || { log "boot did not complete"; exit 1; }

# NEW: wait for Package Manager *after* boot flags flip
wait_for_pm

log "install APK"
retry "adb install -r -d -t app-debug.apk"

log "wake device"
adb shell input keyevent 82 || true

log "SMOKE_OK"