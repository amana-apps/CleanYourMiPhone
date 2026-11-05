<p align="center">
  <img src="docs/banner.svg" alt="CleanYourMiPhone" width="100%">
</p>

<p align="center">
  <a href="https://github.com/amana-apps/CleanYourMiPhone/actions/workflows/ci.yml"><img src="https://github.com/amana-apps/CleanYourMiPhone/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/amana-apps/CleanYourMiPhone" alt="MIT license"></a>
</p>

Remove ads, trackers and bloat from Xiaomi, Redmi and POCO phones, then make them
feel faster. It runs from a Linux or macOS computer over USB. You don't need root
or an unlocked bootloader.

> [!WARNING]
> **Early release, use at your own risk.** The script has only been tested against
> a fake `adb` so far. Its recommended package list was tested by hand on one phone
> (see [Tested devices](#tested-devices)). Packages differ between models, regions
> and system versions, so start with `check`, `scan` and the `clean` preview.

## Features

| | |
|---|---|
| **Preview first** | Nothing changes without `--apply` and a confirmation |
| **Backup** | Saves your package list before removing anything |
| **Protected list** | Refuses packages that can cause boot loops or lockouts |
| **Honest undo** | Marks apps that can't be restored before you remove them |
| **Sideload check** | Lists apps that didn't come from the Play Store |
| **Speed report** | Shows RAM, storage, animation settings and top memory users |
| **Private** | Talks only to your phone over USB and sends nothing online |

## Quick start

**1. Install ADB**

```bash
sudo apt install adb
```

On macOS, use `brew install --cask android-platform-tools`.

**2. Turn on USB debugging**

1. Go to **Settings → About phone** and tap **OS version** seven times.
2. Go to **Settings → Additional settings → Developer options** and turn on
   **USB debugging**.
3. Connect the phone by USB, then tap **Allow** on the prompt.

**3. Run the tool**

```bash
git clone https://github.com/amana-apps/CleanYourMiPhone.git
cd CleanYourMiPhone
./cleanyourmiphone.sh check
./cleanyourmiphone.sh scan
./cleanyourmiphone.sh clean
```

`clean` only shows a preview. When you're happy with the list, back up anything
important and run:

```bash
./cleanyourmiphone.sh clean --apply
```

Then reboot and test calls, SMS, mobile data, fingerprint unlock and the camera.

## Commands

| Command | What it does | Changes the phone? |
|---|---|---|
| `check` | Confirms the phone is connected and authorized | No |
| `scan` | Shows what can be removed and flags sideloaded apps | No |
| `clean` | Previews removals | No |
| `clean --apply` | Removes the recommended packages after you confirm | **Yes** |
| `clean --optional --apply` | Also asks about each optional package | **Yes** |
| `restore <package>` | Brings back a removed package | **Yes** |
| `restore --all` | Brings back everything the tool removed | **Yes** |
| `speed` | Shows RAM, storage, animations and top memory users | No |

## How it works

The tool runs `pm uninstall --user 0`, which removes a package for your user
profile. System apps stay in the read-only system partition, so `restore` can bring
them back, and a factory reset restores them too. An app that had been updated
comes back as its older factory version.

> [!IMPORTANT]
> **Not every removal can be undone this way.** Some Xiaomi apps are installed as
> normal apps with no system copy, so they're deleted completely and must be
> reinstalled from a store. The tool marks these as `NOT RESTORABLE`.

## Make it faster

Run `./cleanyourmiphone.sh speed`, then follow the [speed guide](docs/speed-guide.md).
Shorter animations and fewer background apps make the biggest difference. Budget
phones will feel smoother, but they won't match high-end hardware.

## Package lists

| File | Purpose |
|---|---|
| [`recommended.txt`](lists/recommended.txt) | Ads, analytics and promo packages |
| [`optional.txt`](lists/optional.txt) | Apps you may want to keep; asked one at a time |
| [`protected.txt`](lists/protected.txt) | Never removed, even if added to another list |

## Tested devices

| Model | System | Recommended list | Script |
|---|---|---|---|
| Redmi 15 (`25062RN2DA`) | HyperOS 3, Android 16 | Removed by hand; calls, SMS, data, fingerprint and camera still worked | Not yet run |

`optional.txt` hasn't been tested on a real phone. Tried it on your phone?
[Send a device report](https://github.com/amana-apps/CleanYourMiPhone/issues/new?template=device-report.yml).

## FAQ

**Will this void my warranty?** It doesn't root the phone or unlock the bootloader,
but warranty terms vary, so check yours.

**Will the apps come back?** Major system updates can bring some back. Run the tool
again if that happens.

**Does it work on Windows?** Not directly. It needs a Bash shell with access to ADB.

**Does it block all tracking?** No. Apps you install can track you too. Private DNS
in the [speed guide](docs/speed-guide.md) blocks many more ad and tracker domains.

## Contributing

Device reports are the most useful help. See [CONTRIBUTING.md](CONTRIBUTING.md), and
[SECURITY.md](SECURITY.md) for security problems. Changes are listed in the
[changelog](CHANGELOG.md).

## License

[MIT](LICENSE). Not affiliated with or endorsed by Xiaomi. Xiaomi, Redmi, POCO,
MIUI and HyperOS are trademarks of their respective owners.
