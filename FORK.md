# caelestia-shell (personal fork)

Personal fork of [caelestia-dots/shell](https://github.com/caelestia-dots/shell)
with cherry-picked features and fixes from upstream development branches.

## What's different from upstream `main`

### Merged

- **Per-monitor popup notifications** — notification state (hover pause, fullscreen
  detection, expire timers) is tracked independently per monitor. A fullscreen app on
  one screen no longer blocks popups on the other. (PR #2255 + stack)
- **Custom notification actions** — apps can expose custom actions through notification
  hints. (PR #2259)
- **actionOnClick default fix** — the default action is properly invoked when
  `actionOnClick` is configured. (PR #2262)

### Planned

- **Per-workspace wallpaper** — each workspace remembers its own wallpaper. Requires
  porting PR #2210 from QML to the new C++ `Scheme::Wallpapers` class.

## Syncing with upstream

```sh
git fetch origin
git merge origin/main
```

The `custom/main` branch tracks upstream `main` with our additions on top.

## License

GPL-3.0, same as upstream. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for attribution.
