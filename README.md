# CleanYourMiPhone

Remove ads, trackers and bloat from Xiaomi, Redmi and POCO phones, then make them
feel faster. It runs from a Linux or macOS computer over USB. You don't need root
or an unlocked bootloader.

> **Use at your own risk.** The lists are tested on one phone only (see
> [Tested devices](#tested-devices)). Packages differ between models, regions and
> system versions.

## What it does

- Shows what can be removed before anything changes
- Saves a backup of your package list before removing anything
- Refuses to touch packages that can cause boot loops
- Warns you about apps that can't be restored
- Flags sideloaded apps so you can check them
- Reports your RAM, storage and top memory users

## How it works

The tool runs `pm uninstall --user 0`, which removes a package for your user
profile. System apps stay in the read-only system partition, so they can come back
with one command, and a factory reset restores them too.

**Not every removal can be undone this way.** Some Xiaomi apps are installed as
normal apps with no system copy, so they're deleted completely and have to be
reinstalled from a store. The tool marks these as `NOT RESTORABLE`.

## Before you start

1. Install ADB:

   ```bash
   sudo apt install adb         # Debian, Ubuntu, Mint
   brew install android-platform-tools   # macOS
   ```

2. On the phone, go to **Settings → About phone** and tap **OS version** seven times.
3. Go to **Settings → Additional settings → Developer options** and turn on
   **USB debugging**.
4. Connect the phone with a USB cable, then tap **Allow** on the prompt.
5. Back up anything important.

## Usage

```bash
git clone https://github.com/amana-apps/CleanYourMiPhone.git
cd CleanYourMiPhone
./cleanyourmiphone.sh check
./cleanyourmiphone.sh scan
./cleanyourmiphone.sh clean
./cleanyourmiphone.sh clean --apply
```

`clean` on its own only shows a preview. Add `--apply` to remove the packages after
you confirm.

To go through the optional list one app at a time:

```bash
./cleanyourmiphone.sh clean --optional --apply
```

After cleaning, reboot and test calls, SMS, mobile data, fingerprint unlock and the
camera. Removed packages can come back after a major system update, so you can
run the tool again.

## Undo a removal

```bash
./cleanyourmiphone.sh restore com.miui.analytics
./cleanyourmiphone.sh restore --all
```

Restoring an app that had been updated brings back its older factory version.

## Make it faster

```bash
./cleanyourmiphone.sh speed
```

Then follow the [speed guide](docs/speed-guide.md). Shorter animations and fewer
background apps make the biggest difference. Budget phones will feel smoother, but
they won't match high-end hardware.

## Package lists

| File | Purpose |
|---|---|
| [`lists/recommended.txt`](lists/recommended.txt) | Ads, analytics and promo packages |
| [`lists/optional.txt`](lists/optional.txt) | Apps you may want to keep; asked one at a time |
| [`lists/protected.txt`](lists/protected.txt) | Never removed, even if added to another list |

## Tested devices

| Model | System | Result |
|---|---|---|
| Redmi 15 (`25062RN2DA`) | HyperOS 3, Android 16 | `recommended.txt` removed; calls, SMS, data, fingerprint and camera still worked |

The packages in `recommended.txt` were removed by hand on that phone using the same
ADB commands. **The script itself has only been run against a fake `adb` so far, not
a real phone**, so start with `check`, `scan` and the `clean` preview, and please
report what you see. `optional.txt` hasn't been tested on a real phone either.

## Contributing

Tested on another phone? Open an issue or pull request with your model, system
version, what you removed and what happened. Don't include your serial number or
your backup files, because they identify your phone and your apps.

Run the offline tests with `bash tests/run.sh`. They use a fake `adb`, so they
never touch a phone.

## License

[MIT](LICENSE). Not affiliated with or endorsed by Xiaomi.
