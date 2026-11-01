# Screenshots

The demo GIFs embedded in the package and example READMEs (via raw.githubusercontent.com URLs, so they also render on pub.dev).

| File | Shows |
|---|---|
| `hero.gif` | The two game scenes (`example/assets/scene_*.jpg`) cycling diamond → circle iris → diagonal wipe → circle with a black cover and hold. |
| `diamond.gif`, `circle.gif`, `wipe.gif`, `clock.gif`, `polygon.gif`, `dissolve.gif`, `fade.gif`, `bars.gif` | One transition each on a 320 px square: push the dark Flutter-logo page, hold, pop back. |
| `cover-fade.gif` | Wipe with a black `TransitionCover` and a 600 ms hold. |

## Regenerating

All of them come from one script that renders the real shaders frame by frame — no device or screen recording:

```sh
cd example
flutter test --enable-impeller tool/readme_gifs_test.dart
```

It writes every GIF here in about 15 seconds. Frames are rendered at 2× and downsampled, encoded at 25 fps with one shared palette per GIF, and only changed pixels are stored per frame, which keeps each file under 1 MB. Edit the timelines in [`example/tool/readme_gifs_test.dart`](../example/tool/readme_gifs_test.dart) to change what's shown.
