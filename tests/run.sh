#!/usr/bin/env bash
# Offline tests using tests/fake-adb. Run with: bash tests/run.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="$HERE/../cleanyourmiphone.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export ADB="$HERE/fake-adb" FAKE_ADB_LOG="$TMP/calls" CYMP_BACKUP_DIR="$TMP/backups"
pass=0; fail=0
t() { if eval "$2"; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }

: >"$FAKE_ADB_LOG"
out="$(bash "$TOOL" clean)"
t "preview uninstalls nothing" '! grep -q "pm uninstall" "$FAKE_ADB_LOG"'
t "preview lists a recommended package" 'grep -q com.miui.analytics <<<"$out"'
t "preview flags user app as not restorable" 'grep "com.mi.global.shop" <<<"$out" | grep -q "NOT RESTORABLE"'
t "preview skips packages not installed" '! grep -q com.miui.msa.global <<<"$out"'

out="$(bash "$TOOL" scan)"
t "scan flags sideloaded apps" 'grep -q com.sideloaded.app <<<"$out"'
t "scan uninstalls nothing" '! grep -q "pm uninstall" "$FAKE_ADB_LOG"'

: >"$FAKE_ADB_LOG"
cp "$HERE/../lists/recommended.txt" "$TMP/rec.bak"
echo 'com.miui.home|protected test' >>"$HERE/../lists/recommended.txt"
out="$(bash "$TOOL" clean)"
cp "$TMP/rec.bak" "$HERE/../lists/recommended.txt"
t "protected package is refused" 'grep -q "Skipping protected package: com.miui.home" <<<"$out"'

mkdir -p "$TMP/backups"
printf '2026-01-01 system com.miui.analytics\n2026-01-01 user com.mi.global.shop\n' >"$TMP/backups/removed.log"
: >"$FAKE_ADB_LOG"
out="$(bash "$TOOL" restore --all)"
t "restore --all restores system packages" 'grep -q "restored com.miui.analytics" <<<"$out"'
t "restore --all reports user apps" 'grep -q "cannot restore com.mi.global.shop" <<<"$out"'

echo "passed $pass, failed $fail"
[ "$fail" -eq 0 ]
