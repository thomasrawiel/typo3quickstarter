# PHP step debugging (Xdebug)

Xdebug is part of DDEV's web container already — it doesn't have to be installed. It's just **switched off by default**, because it adds noticeable overhead to every single request, and most instances never get debugged.

## `--xdebug`: on from the first start

```bash
./typo3-ddev-setup.sh --release=13 --xdebug
```

Sets `xdebug_enabled` during `ddev config`, so Xdebug is live from the very first `ddev start` — no `ddev xdebug on` and no container restart afterwards. The final summary reminds you of the server name your IDE needs.

## Toggling it later

Both directions work at any time, from inside the project directory:

```bash
ddev xdebug on       # or: enable, true
ddev xdebug off      # or: disable, false
ddev xdebug toggle
ddev xdebug status
```

So `--xdebug` isn't a decision you're stuck with — it just saves you the extra step on instances you already know you'll debug. Leave it off for instances you only want to click around in.

## IDE setup

The one thing your IDE needs to get right is the **server name**, which must match the instance's hostname exactly:

```
typo3-v13-a1b2.ddev.site
```

You do *not* need to set `PHP_IDE_CONFIG` yourself — DDEV already sets it inside the web container, pointing at that same hostname.

### PhpStorm

1. `Settings → PHP → Servers`, add a server named exactly `<project>.ddev.site`, port 443, debugger Xdebug.
2. Tick *Use path mappings* and map your local project root to `/var/www/html`.
3. Click *Start Listening for PHP Debug Connections*, set a breakpoint, load the page.

### VS Code

Install the *PHP Debug* extension, then add a listen configuration to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/var/www/html": "${workspaceFolder}"
      }
    }
  ]
}
```

## Notes

- With `--xdebug`, the install output contains a `Xdebug: [Step Debug] Could not connect to debugging client. Tried: host.docker.internal:9003` line after each TYPO3 CLI command. That's expected and harmless - Xdebug is active in the CLI too and looks for a listener that isn't running yet during setup.
- Xdebug 3 connects back to your IDE on port **9003** — if nothing ever hits a breakpoint, that's the first thing to check, along with `ddev xdebug status`.
- CLI runs are debugged the same way: `ddev exec ./vendor/bin/typo3 <command>` with the listener active.
- Everything here is DDEV's own Xdebug integration; this script only flips the switch for you. For the full picture — remote setups, `xdebug_ide_location`, troubleshooting — see [DDEV's step debugging docs](https://docs.ddev.com/en/stable/users/debugging-profiling/step-debugging/).

See also [development-settings.md](development-settings.md) for the debug settings every instance gets regardless of this flag.
