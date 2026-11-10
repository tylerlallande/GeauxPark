# GeauxPark MVP demo runbook

Use this checklist before recording or presenting the MVP.

## Preflight

1. Connect the Mac and phone to the same non-guest Wi-Fi network.
2. Turn off VPNs and allow incoming Dart/Flutter connections if macOS asks.
3. From the repository root, verify the release candidate:

   ```bash
   git status
   flutter analyze
   flutter test
   flutter build web --release
   flutter build apk --release
   ```

4. Start the complete demo environment:

   ```bash
   ./tool/run_lan_demo.sh 8081 --release
   ```

5. Open the printed phone URL. Confirm that the terminal also prints a parking
   API URL on port `8080`.

## Suggested three-minute recording

1. **Problem and home:** Explain that GeauxPark helps LSU students and visitors
   choose parking before arrival. Search for a known lot and show the filters.
2. **Permit decision:** Open Profile, select a permit, and return to Home or Map
   to show eligible lots highlighted and restricted lots dimmed.
3. **Map decision:** Open Map, select a color-coded lot, and explain the
   availability density gradient.
4. **Details and server:** Open the lot details to show its server-backed price,
   permit rules, hours, and location information.
5. **Useful actions:** Save the lot, submit an availability report, and show the
   Saved tab. If browser location permission is available, demonstrate the
   built-in route; otherwise explain that location is intentionally permission
   gated and continue without it.

## Recovery plan

- If the phone cannot open the app, verify both devices are on the same Wi-Fi,
  then retry with the URL printed by the launcher.
- If location is blocked by the mobile browser, continue with search, permits,
  map selection, details, saving, and occupancy reporting.
- If the API stops, the app automatically retains its bundled 18-lot catalog so
  the primary demo remains usable.
- Use the release build for recording. Debug mode supports hot reload but is not
  representative of scrolling or transition performance.

## Release

After the final feature branch has been merged into `main` and GitHub Actions is
green, create the first tagged release from the exact verified commit:

```bash
git switch main
git pull --ff-only origin main
git tag -a v1.0.0 -m "GeauxPark MVP v1.0.0"
git push origin v1.0.0
```

The tag triggers GitHub Actions to build and publish the APK. Do not create the
tag until the team agrees that the recording candidate is final.
