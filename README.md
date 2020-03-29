# Thumper

A [`Thumper`] is a flutter widget that controls an `Iterable`.

![widget screen shot][shot0]

Buttons allow reset, forward step, and play/pause.
A slider controls the thumper's frequency (the iteration speed).

There's no backward step, as the basic Iterator interface
doesn't require a reversible state generator.

### Example

The [example] iterates through a list of [fruits].

| initial                 | playing                 |
| ----------------------- | ----------------------- |
| ![example widget use 1][shot1] | ![example widget use 1][shot2] |


To try it in chrome, install [beta channel flutter] then:

```bash
# Confirm you have some devices.
flutter devices

# Get the code
git clone git@github.com:monopole/thumper.git
cd thumper

# then either
make demo-chrome
# or
make demo-android
```

For a more complex `Thumper` demo see the [`GolGrid`] widget.

[beta channel flutter]: https://flutter.dev/docs/get-started/web
[`Thumper`]: https://pub.dev/packages/thumper
[fruits]: lib/data/fruit.dart
[example]: example/lib/main.dart
[shot0]: images/thumper.png
[shot1]: images/shot1.png
[shot2]: images/shot2.png
[`GolGrid`]: https://pub.dev/packages/gol_grid
[flutter]: https://flutter.dev/docs/get-started/install
