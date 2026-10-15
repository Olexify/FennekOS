# Contributing to Fennek OS

Thanks for helping. Fennek OS is a Linux desktop for **people who want a familiar, classic desktop**: it should be easy to use,
stay safe and private, and last long on battery. Changes are judged by that goal.

## Ways to help

- **Report a bug.** Open an issue and pick "Bug report". Include your Fennek version
  (`rpm-ostree status`), your hardware, and the steps that show the problem.
- **Suggest a feature.** Open an issue and pick "Feature request". Say what you were trying to do and how you're
  used to doing it, if that's relevant.
- **Fix something.** Open a pull request. For anything bigger than a small fix, open an issue first so we can
  agree on the approach before you spend time on it.
- **Security problems:** don't open a public issue. See [SECURITY.md](SECURITY.md).

## How the project is built

Fennek OS is a [bootc](https://containers.github.io/bootc/) image. Everything we add on top of the base
(Universal Blue's Kinoite, which is Fedora KDE) lives in three places:

| Path | What it holds |
|---|---|
| `Containerfile` | the base image, plus one build step |
| `build.sh` | packages, patches and settings, run once at build time |
| `system_files/` | files copied as-is into the image (`/usr`, `/etc`) |

The kernel, KDE and Fedora are reviewed by their own projects. Here, you only review our layer.

### Build and test locally

You need podman. Docker can't handle the base image's ~256 layers.

```bash
base=$(bash verify-base.sh)                       # checks the base image's signature, prints its digest
podman build --build-arg BASE_IMAGE=$base -f Containerfile -t fennek:dev .
podman run --rm -v ./test.sh:/t.sh:ro fennek:dev bash /t.sh
```

To check the Windows-program sandbox, run `tests/sandbox-test.sh` (see SCOPE.md, "Build").

## Rules for changes

1. **CI must pass.** Every pull request builds the image and runs `test.sh`.
2. **Add a test.** Any new behavior gets a check in `test.sh`, or a `--selftest` in the tool itself.
3. **No telemetry.** Nothing may contact a server unless the user started it or it's documented in SCOPE.md
   ("PRIVACY" list).
4. **Patching other projects' files:** only by replacing the whole file, never by editing it in place, and with
   an `assert` so the build fails if upstream changes the code (see `build.sh`).
5. **Keep it small.** Use what the base already provides before adding packages, and simple code before
   clever code.
6. **Pinned and verified downloads.** Anything fetched during the build needs a fixed version and a sha256
   checksum.

## Licensing

Fennek OS's own code is licensed under [GPL-3.0](LICENSE). By contributing, you agree your contribution is
licensed under it too. Bundled third-party components keep their own licenses, for example
`system_files/usr/share/plasma/plasmoids/com.github.zren.tiledmenu` (GPL-2.0-or-later, see its NOTICE).

## Decisions

The maintainer ([@Olexify](https://github.com/Olexify)) merges pull requests and has the final say on direction.
Disagreeing is fine: say why in the issue or pull request.
