# Contributing

Thanks for helping. Reports from real phones are the most useful contribution,
because packages differ between models, regions and system versions.

## Report your phone

Open a [device report](https://github.com/amana-apps/CleanYourMiPhone/issues/new?template=device-report.yml)
with your model, system version, what you removed and what happened.

## Change a package list

- Put one package per line: `package|short description`.
- Only add to `recommended.txt` if you've removed the package on a real phone and
  confirmed calls, SMS, mobile data, fingerprint and camera still work.
- Add a package to `protected.txt` if removing it broke something, and say what
  happened in your pull request.

## Change the script

Run these before opening a pull request:

```bash
bash tests/run.sh
shellcheck --severity=warning cleanyourmiphone.sh tests/run.sh tests/fake-adb
```

The script must never change a phone without `--apply` and a confirmation.

## Protect your privacy

Don't post your serial number or anything from `backups/`. Those files identify
your phone and list your apps.
