#!/usr/bin/env bash
# CleanYourMiPhone: remove ads, trackers and bloat from Xiaomi phones over ADB.
# No root needed. Nothing changes on the phone without --apply and a confirmation.
set -u

VERSION="0.1.0"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LISTS="${CYMP_LIST_DIR:-$ROOT/lists}"
BACKUPS="${CYMP_BACKUP_DIR:-$ROOT/backups}"
REMOVED_LOG="$BACKUPS/removed.log"
ADB="${ADB:-adb}"

say()  { printf '%s\n' "$*"; }
die()  { printf 'Error: %s\n' "$*" >&2; exit 1; }
sh_()  { "$ADB" shell "$@" </dev/null 2>/dev/null | tr -d '\r'; }
prop() { sh_ getprop "$1"; }

usage() {
  cat <<'TXT'
Usage: ./cleanyourmiphone.sh <command>

  check                     Check the phone is connected and authorized
  scan                      Show what can be removed and flag sideloaded apps
  clean [--optional]        Preview removals (changes nothing)
  clean [--optional] --apply
                            Back up the package list, then remove packages
  restore <package>...      Bring back removed packages
  restore --all             Bring back everything this tool removed
  speed                     Show RAM, storage, animation and memory use
  version                   Show the version

--optional asks about each package in lists/optional.txt.
TXT
}

require_device() {
  command -v "$ADB" >/dev/null 2>&1 || die "adb not found. See the README for install steps."
  local state
  state="$("$ADB" get-state 2>&1 | tr -d '\r')"
  case "$state" in
    device) ;;
    *unauthorized*) die "Phone not authorized. Unlock it and tap Allow on the USB debugging prompt." ;;
    *) die "No phone found. Check the cable and that USB debugging is on." ;;
  esac
  [ "$("$ADB" devices | grep -c $'\tdevice$')" -eq 1 ] || die "Connect exactly one phone."
}

require_xiaomi() {
  local brand
  brand="$(prop ro.product.manufacturer | tr '[:upper:]' '[:lower:]')"
  [ "$brand" = "xiaomi" ] || die "This tool is for Xiaomi, Redmi and POCO phones (found: ${brand:-unknown})."
}

packages()     { sh_ pm list packages "$@" | sed 's/^package://' | sort -u; }
list_entries() { grep -vE '^[[:space:]]*(#|$)' "$1"; }
is_protected() { list_entries "$LISTS/protected.txt" | grep -qxF "$1"; }

load_state() {
  INSTALLED="$(packages --user 0)"
  USER_APPS="$(packages -3 --user 0)"
}
is_installed() { grep -qxF "$1" <<<"$INSTALLED"; }
is_user_app()  { grep -qxF "$1" <<<"$USER_APPS"; }

device_line() {
  say "Phone:   $(prop ro.product.marketname) ($(prop ro.product.model))"
  say "Android: $(prop ro.build.version.release)  HyperOS/MIUI: $(prop ro.mi.os.version.name) $(prop ro.miui.ui.version.name)"
}

cmd_check() {
  require_device
  require_xiaomi
  device_line
  say "Connection OK."
}

show_list() {
  local file="$1" title="$2" pkg desc tag found=0
  say ""
  say "$title"
  while IFS='|' read -r pkg desc; do
    is_installed "$pkg" || continue
    found=$((found + 1))
    tag=""
    is_user_app "$pkg" && tag=" [NOT RESTORABLE: must be reinstalled from a store]"
    printf '  %-45s %s%s\n' "$pkg" "$desc" "$tag"
  done < <(list_entries "$file")
  [ "$found" -gt 0 ] || say "  (none found)"
}

cmd_scan() {
  require_device
  require_xiaomi
  device_line
  load_state
  show_list "$LISTS/recommended.txt" "Recommended removals:"
  show_list "$LISTS/optional.txt" "Optional removals:"
  say ""
  say "Sideloaded apps (not from the Play Store). Check that you recognize these:"
  sh_ pm list packages -3 -i --user 0 | sed 's/^package://' \
    | grep -E 'installer=(null|com\.google\.android\.packageinstaller|com\.miui\.global\.packageinstaller)$' \
    | awk '{print "  " $1}' | sort || true
  say ""
  say "Nothing was changed. Run ./cleanyourmiphone.sh clean to preview removals."
}

backup_packages() {
  mkdir -p "$BACKUPS"
  local file
  file="$BACKUPS/packages-$(date +%Y%m%d-%H%M%S).txt"
  sh_ pm list packages -f -u | sort >"$file"
  [ -s "$file" ] || die "Could not save the package backup, so nothing was removed."
  say "Package list saved to $file"
}

confirm() {
  local reply
  read -r -p "$1 [y/N] " reply </dev/tty || return 1
  [ "$reply" = "y" ] || [ "$reply" = "Y" ]
}

cmd_clean() {
  local optional=0 apply=0 arg
  for arg in "$@"; do
    case "$arg" in
      --optional) optional=1 ;;
      --apply) apply=1 ;;
      *) die "Unknown option: $arg" ;;
    esac
  done
  require_device
  require_xiaomi
  device_line
  load_state

  local targets=() pkg desc
  while IFS='|' read -r pkg desc; do
    is_installed "$pkg" || continue
    if is_protected "$pkg"; then say "Skipping protected package: $pkg"; continue; fi
    targets+=("$pkg|$desc")
  done < <(list_entries "$LISTS/recommended.txt")

  if [ "$optional" -eq 1 ]; then
    while IFS='|' read -r pkg desc; do
      is_installed "$pkg" || continue
      if is_protected "$pkg"; then say "Skipping protected package: $pkg"; continue; fi
      if [ "$apply" -eq 0 ] || confirm "Remove $pkg ($desc)?"; then
        targets+=("$pkg|$desc")
      fi
    done < <(list_entries "$LISTS/optional.txt")
  fi

  if [ "${#targets[@]}" -eq 0 ]; then
    say "Nothing to remove."
    return 0
  fi

  say ""
  say "Packages to remove (${#targets[@]}):"
  local item
  for item in "${targets[@]}"; do
    pkg="${item%%|*}"; desc="${item#*|}"
    if is_user_app "$pkg"; then
      printf '  %-45s %s [NOT RESTORABLE]\n' "$pkg" "$desc"
    else
      printf '  %-45s %s\n' "$pkg" "$desc"
    fi
  done

  if [ "$apply" -eq 0 ]; then
    say ""
    say "Preview only, nothing was changed. Add --apply to remove these."
    return 0
  fi

  say ""
  say "NOT RESTORABLE apps are deleted fully and must be reinstalled from a store."
  confirm "Remove these ${#targets[@]} packages?" || { say "Cancelled, nothing was changed."; return 0; }
  backup_packages

  local ok=0 failed=0 result kind
  for item in "${targets[@]}"; do
    pkg="${item%%|*}"
    kind=system; is_user_app "$pkg" && kind=user
    result="$(sh_ pm uninstall --user 0 "$pkg")"
    if [ "$result" = "Success" ]; then
      ok=$((ok + 1))
      printf '%s %s %s\n' "$(date +%F)" "$kind" "$pkg" >>"$REMOVED_LOG"
      say "  removed  $pkg"
    else
      failed=$((failed + 1))
      say "  FAILED   $pkg: ${result:-no response}"
    fi
  done
  say ""
  say "Removed $ok, failed $failed. Reboot, then test calls, SMS, data, fingerprint and camera."
  say "If the SIM asks for a PIN after the reboot, that is normal."
}

cmd_restore() {
  [ "$#" -gt 0 ] || die "Name a package, or use --all."
  require_device
  local names=() pkg result kind
  if [ "$1" = "--all" ]; then
    [ -f "$REMOVED_LOG" ] || die "No removal log found at $REMOVED_LOG"
    while read -r _ kind pkg; do
      if [ "$kind" = "user" ]; then
        say "  cannot restore $pkg: reinstall it from a store"
      else
        names+=("$pkg")
      fi
    done <"$REMOVED_LOG"
  else
    names=("$@")
  fi
  [ "${#names[@]}" -gt 0 ] || return 0
  for pkg in "${names[@]}"; do
    result="$(sh_ cmd package install-existing "$pkg")"
    case "$result" in
      *"installed for user"*) say "  restored $pkg" ;;
      *) say "  FAILED   $pkg: ${result:-no response} (it may need reinstalling from a store)" ;;
    esac
  done
}

cmd_speed() {
  require_device
  require_xiaomi
  device_line
  say ""
  say "Memory:"
  sh_ cat /proc/meminfo | awk '/^(MemTotal|MemAvailable|SwapTotal|SwapFree):/ {printf "  %-14s %.1f GB\n", $1, $2/1048576}'
  say ""
  say "Storage (/data):"
  sh_ df -h /data | tail -1 | awk '{print "  " $4 " free of " $2 " (" $5 " used)"}'
  say ""
  say "Animation scales (0.5 feels faster, see docs/speed-guide.md):"
  local s
  for s in window_animation_scale transition_animation_scale animator_duration_scale; do
    say "  $s = $(sh_ settings get global "$s")"
  done
  say ""
  say "Top apps by memory:"
  sh_ dumpsys meminfo | sed -n '/Total PSS by process/,/Total PSS by OOM/p' \
    | grep -E 'K: [a-z]+\.[a-z]' | grep -vE 'K: (com\.android\.systemui|com\.miui\.home) ' | head -10 | sed 's/ (pid.*//;s/^ */  /'
}

main() {
  local cmd="${1:-}"
  [ "$#" -gt 0 ] && shift
  case "$cmd" in
    check)   cmd_check ;;
    scan)    cmd_scan ;;
    clean)   cmd_clean "$@" ;;
    restore) cmd_restore "$@" ;;
    speed)   cmd_speed ;;
    ""|-h|--help|help) usage ;;
    -v|--version|version) say "CleanYourMiPhone $VERSION" ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
