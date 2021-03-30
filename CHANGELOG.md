# Changelog

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
