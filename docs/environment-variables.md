# Environment variables

```bash
./typo3-ddev-setup.sh --release=13 --env=MY_API_TOKEN=abc123
```

`--env` sets environment variables in the web container. They're passed to `ddev config` before the project is ever started, so they're in place for the whole install — TYPO3's own setup, every `composer` call, and every request afterwards.

Like `--require` and `--extension`, you can repeat the flag or list several values after one occurrence, separated by spaces:

```bash
./typo3-ddev-setup.sh --release=13 --env=FOO=bar BAZ=qux --env=ANOTHER=1
```

The same syntax gotcha applies as in [composer-packages.md](composer-packages.md): bare values attach to whichever of `--require`/`--extension`/`--env` came last, so keep each flag's values together.

## Overriding the script's own defaults

The script sets `TYPO3_CONTEXT=Development` itself (see [development-settings.md](development-settings.md)). If you pass the same variable via `--env`, yours wins — the default is dropped rather than written twice:

```bash
./typo3-ddev-setup.sh --release=13 --env=TYPO3_CONTEXT=Development/DDEV
```

`PHP_IDE_CONFIG` is worth knowing about but not worth setting: DDEV already provides it inside the web container — see [xdebug.md](xdebug.md).

## Checking what arrived

```bash
ddev exec printenv TYPO3_CONTEXT
```

The variables also show up under `web_environment` in the project's `.ddev/config.yaml`, so you can edit or extend them there afterwards (`ddev restart` to apply).

## Limitation: no commas

`ddev config` takes its web environment as a single comma-separated list, so a comma inside a value would silently turn into a second, bogus variable. The script rejects those up front rather than passing them through:

```
Error: --env values cannot contain a comma (ddev config takes one comma-separated list): A=1,B=2
```

For a value that genuinely needs a comma, set it after setup — either in `.ddev/config.yaml`, or in a `.ddev/.env.web` file, which DDEV v1.23.5+ reads into the web container on its own:

```bash
ddev dotenv set .ddev/.env.web --my-list="a,b,c"
ddev restart
```
