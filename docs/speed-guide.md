# Speed guide

Run `./cleanyourmiphone.sh speed` first to see where your phone stands. These
steps are done on the phone. Menu names vary by HyperOS or MIUI version, so use
the search bar in Settings if you can't find one.

## 1. Shorten animations

This is the biggest visible change.

1. Go to **Settings → Additional settings → Developer options**.
2. Set **Window animation scale**, **Transition animation scale** and
   **Animator duration scale** to **0.5x**.

## 2. Limit heavy background apps

Open **Settings → Apps**, pick an app, turn **Autostart** off, and restrict its
background activity under **Battery saver**. Start with the apps at the top of
the `speed` report.

Restricted apps may send notifications late, so leave your messaging apps alone.

## 3. Remove what you don't use

Every removed app also stops running in the background. Large games are usually
the quickest way to get storage back.

## 4. Block ads with Private DNS

1. Open **Settings → Connection & sharing → Private DNS**.
2. Choose **Private DNS provider hostname**.
3. Enter `dns.adguard-dns.com` and save.

This blocks many ad and tracker domains inside apps. It won't block ads served
from the same domain as an app's content. If an app or a Wi-Fi login page
misbehaves, set Private DNS back to **Off** or **Automatic**.

## 5. Turn off ad personalization

Search Settings for **Ad privacy** and turn off the options there. Leave the
`com.google.android.adservices.api` package installed.

## 6. Restart every few days

This helps most on phones with 6 GB of RAM or less.

## What to skip

- **Cleaner and "RAM booster" apps:** they force apps to reload, which costs
  speed and battery.
- **Lowering the refresh rate:** this saves battery but feels slower.
