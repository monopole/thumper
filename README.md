# Thumper

A [`Thumper`] is a flutter widget that controls an `Iterable`.

Buttons allow reset, forward step, and play/pause.
A slider controls iteration speed.

### Example

The [example] iterates through a list of [fruits].

| initial                 | playing                 |
| ----------------------- | ----------------------- |
| ![screen shot 1][shot1] | ![screen shot 2][shot2] |


To run it, install [beta channel flutter] then:

```bash
git clone git@github.com:monopole/thumper.git
cd thumper/example
flutter -d chrome run
```

For a more complex `Thumper` demo see the [`GolGrid`] widget.

[beta channel flutter]: https://flutter.dev/docs/get-started/web
[`Thumper`]: https://pub.dev/packages/thumper
[fruits]: ./lib/data/fruit.dart
[example]: ./example/lib/main.dart
[shot1]: ./images/shot1.png
[shot2]: ./images/shot2.png
[`GolGrid`]: https://pub.dev/packages/gol_grid
[flutter]: https://flutter.dev/docs/get-started/install
