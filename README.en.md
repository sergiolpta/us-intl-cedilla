# US International + Ç

[Português](README.md) | **English**

Linux keyboard layout support for users with a physical US ANSI keyboard who write in Portuguese.

The project preserves the behavior of **English (US, intl., with dead keys)** and changes only these combinations:

| Combination | Result |
| --- | --- |
| `AltGr + C` | `ç` |
| `AltGr + Shift + C` | `Ç` |

## Project status

The project is currently in pre-release.

The installation, restoration, and uninstallation scripts have been implemented and tested in a sandbox on Linux Mint 22.3 with:

```text
xkb-data 2.41-2ubuntu1.1
```

The real development system remained unchanged during privileged tests.

Validated compatibility:

- Linux Mint 22.3

Planned compatibility, not yet validated on real systems:

- Ubuntu
- Debian
- Pop!_OS

## The problem

The US International layout already supports common accented characters:

| Combination | Result |
| --- | --- |
| `'` + `a` | `á` |
| `'` + `e` | `é` |
| `'` + `i` | `í` |
| `'` + `o` | `ó` |
| `'` + `u` | `ú` |
| `~` + `a` | `ã` |
| `~` + `o` | `õ` |
| `^` + `a` | `â` |
| `^` + `e` | `ê` |

However, the physical `C` key in the `us(intl)` layout is defined as:

```xkb
key <AB03> { [ c, C, copyright, cent ] };
```

This produces:

| Combination | Default result |
| --- | --- |
| `AltGr + C` | `©` |
| `AltGr + Shift + C` | `¢` |

These combinations are less useful for people writing in Portuguese who frequently need `ç` and `Ç`.

## The solution

The project changes only the `<AB03>` key definition to:

```xkb
key <AB03> { [ c, C, ccedilla, Ccedilla ] };
```

No other key in the US International layout should be modified.

## How it works

The project works directly on:

```text
/usr/share/X11/xkb/symbols/us
```

The installer:

1. validates the system and the `xkb-data` package;
2. confirms the original layout state;
3. creates a backup with metadata and a SHA-256 checksum;
4. applies the patch to a temporary file;
5. validates the result;
6. replaces the system file only after all checks succeed.

Backups are stored in:

```text
/var/backups/us-intl-cedilla
```

The directory is protected and accessible only by `root`.

## Installation

Clone the repository:

```bash
git clone https://github.com/sergiolpta/us-intl-cedilla.git
cd us-intl-cedilla
```

Run the checks:

```bash
./tests/regression.sh
./tests/verify.sh
```

Install:

```bash
sudo ./install.sh
```

Then reload the layout or restart the graphical session:

```bash
setxkbmap us intl
```

> In Wayland sessions, `setxkbmap` may not directly control the compositor. In that case, sign out and sign in again, or reselect the keyboard layout in the desktop environment settings.

## Verification

```bash
./tests/verify.sh
```

When installed, the expected result is:

```text
Layout state: modified
```

When not installed or after restoration:

```text
Layout state: original
```

Depending on the script version and system locale, the output may appear in Portuguese.

## Restoration

Restoration replaces the modified file with the latest valid original backup and preserves the backup files:

```bash
sudo ./restore.sh
```

The script:

- selects the latest valid backup;
- validates metadata and checksum;
- confirms that the backup contains the original layout;
- performs a safe replacement;
- confirms the final state;
- is idempotent.

## Uninstallation

Uninstallation restores the official layout and removes persistent project data:

```bash
sudo ./uninstall.sh
```

The script:

- restores the layout when necessary;
- confirms the original state;
- removes the backup directory;
- removes the state directory, when present;
- preserves the cloned repository;
- is idempotent.

## Security

The scripts stop when:

- they are not run with administrative privileges;
- required commands are unavailable;
- the expected XKB file does not exist or cannot be read;
- the target file is a symbolic link;
- the `intl` variant cannot be found;
- the layout state is inconsistent;
- backup files or metadata fail validation;
- the SHA-256 checksum does not match;
- the final result does not match the expected state.

The project does not manually edit:

```text
evdev.xml
base.xml
```

## Automated quality checks

Every push and pull request to `main` runs GitHub Actions checks for:

- Bash syntax;
- ShellCheck;
- regression tests.

The regression test verifies that only the `<AB03>` key is changed.

## Current limitations

- Direct changes to files owned by the `xkb-data` package may be overwritten by system updates.
- Ubuntu, Debian, and Pop!_OS still require validation on real systems.
- There is no `.deb` package yet.
- Wayland activation behavior may vary by desktop environment and compositor.
- Automatic reapplication after an `xkb-data` package update is not implemented yet.

## Project structure

```text
us-intl-cedilla/
├── README.md
├── README.en.md
├── CONTRIBUTING.md
├── LICENSE
├── CHANGELOG.md
├── config.sh
├── install.sh
├── restore.sh
├── uninstall.sh
├── patches/
│   └── us-intl-cedilla.patch
├── tests/
│   ├── verify.sh
│   └── regression.sh
├── docs/
│   ├── architecture.md
│   ├── roadmap.md
│   └── screenshots/
└── .github/
    ├── workflows/
    │   └── quality.yml
    ├── ISSUE_TEMPLATE/
    │   └── bug_report.md
    └── pull_request_template.md
```

## Contributing

Bug reports, tests on other distributions, and improvements are welcome.

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) before submitting changes.

Changes to other keys should be discussed separately because the main scope is limited to the `<AB03>` key.

## License

Distributed under the MIT License. See [`LICENSE`](LICENSE).
