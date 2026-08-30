# Installation

The intended way is to install it once as a command and forget about the file it came from.

```bash
curl -fsSL https://raw.githubusercontent.com/pagea-dev/typo3quickstarter/main/install.sh | bash
```

That gives you `typo3quickstarter`, with `t3quickstarter` as a shorter alias for the same thing, so an instance can be created from any directory without keeping a copy of the script around:

```bash
cd ~/projects/customer-x
t3quickstarter --release=13 --xdebug
```

The instance lands in the directory you're standing in — exactly as if you'd run the script from there. Everything the tool prints back at you names whichever command you actually typed.

From a checkout it's the same installer:

```bash
git clone https://github.com/pagea-dev/typo3quickstarter.git
cd typo3quickstarter
./install.sh
```

## Where it installs to

Default is `~/.local/bin`, which needs no `sudo`. If that directory isn't in your `PATH`, the installer says so and prints the line to add.

```bash
./install.sh --prefix=/usr/local/bin   # machine-wide, usually needs sudo
```

The installer tells you what it's about to do — where the script comes from, which version it is, and whether this is a fresh install, a reinstall or an update:

```
Source:  latest release on GitHub
Version: 0.5.0
Target:  /home/you/.local/bin
Update:  0.4.1 -> 0.5.0

Installed into /home/you/.local/bin:
  typo3quickstarter             the TYPO3 instance creator itself
  t3quickstarter                short alias, symlink to typo3quickstarter
  typo3quickstarter-uninstall   removes all of the above again
```

## Updating

Updating is just installing again — re-run the `curl` line, or `./install.sh` after pulling a newer checkout. The `Update:` line tells you which version you came from.

## Uninstalling

`install.sh` puts a copy of the uninstaller next to the command as `typo3quickstarter-uninstall`, so removing it never depends on having a checkout around:

```bash
typo3quickstarter-uninstall            # add the same --prefix you installed with
```

From a checkout, `./uninstall.sh` does the same thing. It removes the command, its alias and itself.

Installing and removing are separate scripts on purpose, so each does one thing. Both only ever touch files they recognize as their own: a same-named command from somewhere else is neither overwritten on install nor removed on uninstall. Instances you already created are not affected either way — those are removed with the tool's own `--cleanup` (see [instances.md](instances.md)).

## Without installing anything

The script is self-contained, so you can also just take the file and run it where it lies:

```bash
curl -LO https://github.com/pagea-dev/typo3quickstarter/releases/latest/download/typo3-ddev-setup.sh && chmod +x typo3-ddev-setup.sh
./typo3-ddev-setup.sh --release=13
```

Same flags, same behaviour. The only difference is cosmetic: every command the script suggests back to you (`--help`, the cleanup hint at the end of a run) names `./typo3-ddev-setup.sh` instead of `typo3quickstarter`, because it goes by the name it was started under.

## Prerequisites

All of these need [Docker](https://www.docker.com/) and [DDEV](https://ddev.com/get-started/) (v1.22+). The script checks for both and bails out early with a clear error if either is missing or Docker isn't running. The installer only warns — you can install the command before DDEV exists on the machine, you just can't create an instance yet.
