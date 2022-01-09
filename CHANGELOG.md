# Changelog

## 9-Jan-2022

- Bumped to Firebase CLI 10.0.1; Node 16 now comes with npm 8 causing a name change of the image.

## 11-Dec-2021

- Added license for Google's Dev Library

## 3-Sep-2021

- Upgraded to 9.17.0

## 25-Aug-2021

- Pumped up to 9.16.5 ⛽️

## 16-Aug-2021

- Suppressing npm update notifications

## 18-Jul-2021

- Updated `firebase-tools` to 9.16.0

## 5-Jul-2021

- **ADD** (undercover): A user `user` created, for manual use.

   Cloud Build still requires that the image is left without a `USER`.

## 15-Jun-2021

- **CHANGE**: Using "headless" JRE, trims ~10MB off the image

## 7-Jun-2021

- **CHANGE**: No longer needing GNU Make
- Updated to `firebase-tools` 9.12.1.

## 1-Jun-2021

- **CHANGE**: Enabled UI emulation; disabled Pub/Sub; mentioning Storage

   The idea is that people can enable/disable just the emulators they need to prefetch.

## 24-May-2021

- **CHANGE:** `FIREBASE_EMULATORS_PATH` so downstream doesn't need to move the emulator images (`ONBUILD` wasn't picked up by Cloud Build).
- **OPTIMIZATION**: PubSub cached `.zip` removed (496MB image size)

## 21-May-2021

- Upgraded to Firebase tools 9.11.0 and Node.js 16.

## 30-Mar-2021

- Changed to recommending non-regional Container Registry (`gcr.io`) in all cases.

## 27-Mar-2021

- **FIX**: Preloaded emulator packages were not used. Tried solving this, but cannot since Cloud Build **rudely** overrides the home directory, and removes anything we would have placed there. 

  The solution needs one step from consuming parties (now mentioned in the `README`).

## 26-Mar-2021

- Leaving `root` as the user; eliminates Cloud Build problems. 🙂
- Updated to Firebase CLI v. 9.6.1
- Added `curl`
- Updated to `npm` 7.x (7.7.5)

## 25-Mar-2021

- Documenting: Notion about pushing the `latest` image.

## 23-Mar-2021

Found this in excavations, and took it to use!

- Adjusting for use with Cloud Build (not GitHub Packages)
- Updating to later `firebase-tools`: 8.8.1 -> 9.6.0
- Use of `Makefile`
- Pushing to Cloud Registry (for Cloud Build)

## 30-Aug-2020

- Initial release; pushed `8.8.1-node14` to GitHub Packages 🙂
