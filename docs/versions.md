# TYPO3 versions

## Selecting a version

```bash
./typo3-ddev-setup.sh --release=13
```

`-r`/`--release` accepts either a bare major version or a pinned minor/patch release:

| Form | Example | Result |
|---|---|---|
| Major only | `--release=12` | Newest release on that major's LTS line |
| Minor | `--release=12.4` | Same as above for the current major versions (each major only has one LTS minor line) |
| Exact patch | `--release=12.4.20` | Exactly that release, pinned |

No `--release` at all? It defaults to the newest supported major version.

Currently supported major versions:

| `--release` | PHP | Composer constraint |
|---|---|---|
| 11 | 8.1 | `^11.5` |
| 12 | 8.2 | `^12.4` |
| 13 | 8.3 | `^13.4` |
| 14 | 8.4 | `^14.3` |

Only one release line is wired up per major version — extending the version map to a new TYPO3 release is a one-line addition in the script.

> Project folder/DDEV names are always based on the major version (e.g. `typo3-v12-101`), even if you pinned an exact patch release with `--release=12.4.20`.

## Pre-releases (TYPO3 15)

| `--release` | PHP | Composer constraint |
|---|---|---|
| 15 | 8.5 | `dev-main` |

TYPO3 15 has no release yet. It's developed on `main`, and neither `typo3/cms-core` nor `typo3/cms-base-distribution` publish a `15.x` branch on Packagist — `dev-main` (branch alias `15.0.x-dev`) is the only thing that resolves. `--release=15` installs exactly that:

```bash
./typo3-ddev-setup.sh --release=15
```

```
==> TYPO3 15 has no release yet - installing the development branch (dev-main).
    Expect breakage, and expect two installs made on different days to differ.
```

Three things follow from it being a development branch:

- **It's never the default.** Leaving out `--release` still gives you the highest *released* version. You have to ask for 15 by name.
- **It can't be pinned.** `--release=15.0` or `--release=15.0.1` is rejected up front, because there is no such release to pin to — better than failing minutes later inside Composer.
- **It needs PHP 8.5**, which the script sets for you like every other version. Your DDEV has to know that PHP version; if it's too old, `ddev config` says so and updating DDEV fixes it.

The script fixes up two things in the scaffolded `composer.json` before installing:

- **`minimum-stability: dev` plus `prefer-stable: true`.** The base distribution's `main` branch requires every `typo3/cms-*` at `dev-main` but sets no `minimum-stability` of its own, so anything added afterwards — the core extras the script requires, and your own `--require` packages — would be judged against the default `stable` and refused. `prefer-stable` keeps unrelated third-party packages on their stable releases regardless.
- **`config.platform.php` is removed.** That branch still pins it to `8.2.0`, left over from the 14 line, while the `cms-core` it pulls in already requires `^8.5`. The override wins over the PHP that's actually installed, so Composer ends up rejecting its own packages:

  ```
  typo3/cms-core[dev-main, 15.0.x-dev] require php ^8.5 -> your php version
  (8.2.0; overridden via config.platform, actual: 8.5.7) does not satisfy that requirement.
  ```

  Dropping it lets Composer see the container's real PHP — which is the version this script picked for the release anyway.

Once 15.0 is actually released, it moves from the pre-release list into the table above and gets a normal `^15.0` constraint.

## Pinning an exact patch release

`typo3/cms-base-distribution` — the meta-package the script installs — only has a couple of releases of its own (`v12.4.0`, `v12.4.1`, ...). It just bundles the real `typo3/cms-*` packages via the constraints in the table above. So pinning e.g. `--release=12.4.20` can't be done by requesting that version of the distribution package directly — it doesn't exist.

Instead, the script:

1. Scaffolds the project via the normal `^X.Y` constraint with `composer create-project ... --no-install` (files only, no packages installed yet).
2. Rewrites `composer.json`, replacing every `typo3/cms-*` package's `^X.Y` constraint with the exact pinned version.
3. Runs `composer install` to install that exact, fully pinned set of packages.

## ⚠️ Security note: `--no-security-blocking`

Every Composer install/require in this script passes `--no-security-blocking`, printed once up front:

```
==> Installing with --no-security-blocking: disposable test instances, not production
```

Composer normally refuses to install any package version flagged by a known security advisory - and since there's essentially always something flagged somewhere in a TYPO3 release line, this can otherwise block even a completely plain, unpinned `--release=13` the moment Composer has to freshly resolve the full dependency tree (e.g. nothing yet locked, as right after `create-project`). Pinning an old patch release on purpose to reproduce a bug is the most common reason you'd actually want an affected version installed, but the block is bypassed unconditionally rather than only when pinning, since it would otherwise resurface unpredictably. These are disposable local test instances, never anything running in production, so that trade-off is fine here.

## TYPO3 v11 note

TYPO3 v11's native `typo3 setup` CLI command crashes on fresh installs ([TYPO3 Forge #105452](https://forge.typo3.org/issues/105452), closed won't-fix since v11 is EOL). For `--release=11` the script automatically falls back to the legacy `typo3cms install:setup` installer instead, which doesn't have this bug.
