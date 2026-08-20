# Stash Quest

Family savings app for iOS. Log real skips and stashes, run 50 challenges (grown-ups, kids, and family), and watch each person's vault fill up.

## Requirements

- Xcode 15+
- iOS 17+

## Build

```bash
xcodegen generate
xcodebuild -scheme StashQuest -destination 'platform=iOS Simulator,id=E6D74279-EF2F-4D64-BDAA-F399C36E73F4' build
```

## Features

- Family profiles (grown-up and kid) with per-person vaults
- 50 real-money challenges across three audiences
- Skip, stash, and give logging
- Parent Match for kid savings
- Stamps, streaks, vault milestones, and weekly recap
- Optional local reminders (allowance, Coin Friday, $5 Friday)
- Light, dark, and system appearance

## App Store Connect URLs

Use these GitHub pages in App Store Connect (not linked from the app):

- **Marketing URL:** https://github.com/ronb12/StashQuest
- **Privacy Policy:** https://github.com/ronb12/StashQuest/blob/master/PRIVACY.md
- **Terms of Service:** https://github.com/ronb12/StashQuest/blob/master/TERMS.md
- **Support:** https://github.com/ronb12/StashQuest/blob/master/SUPPORT.md

In-app copies live under **You → Legal & Support**.
