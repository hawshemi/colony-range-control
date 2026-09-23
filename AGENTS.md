# Project guidance

## Scope

Keep changes small and follow the existing Lua style. Add dependencies only when needed and explain them first. Keep public documentation focused on players, without internal handoff notes or task lists.

## Compatibility

- Preserve the mod ID `LocalRangeExtender`, author `hawshemi`, existing option keys, and saved-game migration logic.
- Range changes must remain reversible and must not stack across repeated loads or option changes.
- Presets must preserve custom settings. The master switch must restore normal ranges while the mod is loaded.
- Refresh affected caches, connections, heat maps, and range displays when changing gameplay ranges.
- Preserve existing power-cost scaling and other gameplay effects unless the request changes them.
- Before changing game hooks, check the installed game source using a locally supplied path.
- Set each code item's `name` to its Lua filename stem. The editor derives `Code/<name>.lua` on save, so `CodeFileName` alone is insufficient.

## Validation

Install test dependencies from `tests/requirements.txt` when needed. Run the relevant checks from the repository root:

```powershell
python tests/test_ranges.py mod --game-source "$env:GAME_SOURCE"
python tests/test_heat.py --game-source "$env:GAME_SOURCE"
python tests/test_release.py mod --game-source "$env:GAME_SOURCE"
```

Set `GAME_SOURCE` locally to the game source directory. Use the first test for range logic, the second for heat and forestation behavior, and the third for metadata, options, and thumbnail changes. These tests simulate engine services and do not prove in-game behavior. Report what was actually checked.

## Distribution

- Keep option descriptions, metadata, and player instructions consistent with behavior. Include the MIT license in release packages.
- Commit only project code, artwork, documentation, and tests. Keep game source, saves, logs, credentials, and local runtime binaries outside the repository.
- Keep personal filesystem paths out of tracked files, examples, and commit messages. Use environment variables or generic placeholders.
- When asked to install locally, back up the existing mod first. Preserve installed publishing fields, including `pdx_id` and `pdx_version`, and avoid duplicate installations. Close the editor without saving and reopen it after external edits to prevent stale data from overwriting them.
- Preserve the existing Paradox listing ID `160315` when preparing updates. Keep the GitHub URL in `external_links` without repeating it in the description.
- Use a 1280 × 720 JPG thumbnail at about 90% quality, below 2 MiB. The marketplace crops images to 16:9. Keep text inside safe margins and synchronize the root and packaged thumbnails.
- Publish to Paradox Mods only when explicitly requested. A source zip is not the game's packed upload archive.

## Git and communication

Use short, plain commit messages, such as `fix heat range`. Push only when requested and verify the remote branch matches the local commit afterward.

Keep replies brief. Use plain English without emojis, em dashes, or semicolons. Preserve standard wording in license files.
