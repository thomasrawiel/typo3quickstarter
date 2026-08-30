# Installation

Two ways to install, depending on how often you use it.

## A single file, run from where it lies

```bash
curl -LO https://github.com/pagea-dev/typo3quickstarter/releases/latest/download/typo3-ddev-setup.sh
chmod +x typo3-ddev-setup.sh
./typo3-ddev-setup.sh --release=13
```

No install step, nothing added to your system, and the only dependencies are `bash`, `docker` and `ddev`. The instance is created in whatever directory you run it from.

## As a system-wide command

```bash
./install.sh
```

Installs the script as `typo3quickstarter`, plus `t3quickstarter` as a shorter alias for the same thing, so you can create an instance from any directory without keeping a copy of the script around:

```bash
cd ~/projects/customer-x
t3quickstarter --release=13 --xdebug
```

The instance still lands in the directory you're standing in — exactly as if you'd run the script from there. All flags are identical; the tool notices which name it was called under and prints that name back in its help and in the cleanup hint.

Without a checkout, the installer fetches the latest release itself:

```bash
curl -fsSL https://raw.githubusercontent.com/pagea-dev/typo3quickstarter/main/install.sh | bash
```

### Where it installs to

Default is `~/.local/bin`, which needs no `sudo`. If that directory isn't in your `PATH`, the installer says so and prints the line to add.

```bash
./install.sh --prefix=/usr/local/bin   # machine-wide, usually needs sudo
```

### Updating and uninstalling

Updating is just installing again — run `./install.sh` after pulling a newer version, or re-run the `curl` line above to pull the latest release.

```bash
./install.sh --uninstall               # add the same --prefix if you used one
```

The installer only ever touches files it recognizes as its own: a same-named command from somewhere else is neither overwritten on install nor removed on uninstall.

## Prerequisites

Both paths need [Docker](https://www.docker.com/) and [DDEV](https://ddev.com/get-started/) (v1.22+). The script checks for both and bails out early with a clear error if either is missing or Docker isn't running.
