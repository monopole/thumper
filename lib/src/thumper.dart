import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'thumper_bloc.dart';
import 'thumper_event.dart';
import 'thumper_state.dart';

/// A Thumper<E> is a row of controls associated with a ThumperBloc<E>,
/// which in turn contains Iterable<E>.
/// Controls include reset, forward step, play, pause, and speed.
/// There's no backward step, as the Iterator interface (wisely) doesn't
/// require a reversible process.
/// This widget doesn't show E or make an calls on E, but must get an
/// instance of ThumperBloc<E> from the context (hence the parameterization).
/// This widget has a fixed size (like an Icon).
@immutable
class Thumper<E> extends StatelessWidget {
  /// Make a [Thumper].
  const Thumper({
    Key key,
    this.onColor = Colors.lightBlueAccent,
    this.offColor = Colors.blueGrey,
  }) : super(key: key);

  /// Fixed width of this widget in logical pixels.
  static const int width = 330;

  /// Fixed height of this widget in logical pixels.
  static const int height = 60;

  /// Color controls when thumping.
  final Color onColor;

  /// Color controls when not thumping.
  final Color offColor;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Color>('onColor', onColor));
    properties.add(DiagnosticsProperty<Color>('offColor', offColor));
  }

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints.tightFor(
            width: width.toDouble(), height: height.toDouble()),
        child: _controlRow(context),
      );

  Widget _controlRow(BuildContext c) {
    final bloc = BlocProvider.of<ThumperBloc<E>>(c);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      BlocBuilder<ThumperBloc<E>, ThumperState>(
        condition: (previousState, incomingState) =>
            incomingState.power != previousState.power,
        builder: (context, state) => Row(
          children: _buttonList(bloc),
        ),
      ),
      BlocBuilder<ThumperBloc<E>, ThumperState>(
        condition: (previousState, incomingState) =>
            incomingState.speed != previousState.speed,
        builder: (context, state) => _themedSlider(context, bloc),
      ),
    ]);
  }

  Widget _themedSlider(BuildContext c, ThumperBloc<E> bloc) => SliderTheme(
        data: SliderTheme.of(c).copyWith(
          trackHeight: 4,
          thumbColor: onColor,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayColor: Colors.purple.withAlpha(32),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        ),
        child: _rawSlider(bloc),
      );

  Widget _rawSlider(ThumperBloc<E> bloc) => Slider(
        value: bloc.state.speed.unitInterval,
        min: 0,
        max: 1,
        activeColor: onColor,
        divisions: bloc.numDivisions,
        onChanged: (s) => bloc.reactToSpeedValue(s),
      );

  List<Widget> _buttonList(ThumperBloc<E> bloc) {
    switch (bloc.state.power) {
      case ThumperPower.reset:
        {
          return [
            _button(Icons.replay, null),
            _button(
                Icons.skip_next, () => bloc.add(ThumperEvent.thumpedManually)),
            _button(Icons.play_arrow, () => bloc.add(ThumperEvent.resumed)),
          ];
        }
        break;
      case ThumperPower.off:
        {
          return [
            _button(Icons.replay, () => bloc.add(ThumperEvent.rewound)),
            _button(Icons.skip_next,
                () => bloc.add(ThumperEvent.thumpedAutomatically)),
            _button(Icons.play_arrow, () => bloc.add(ThumperEvent.resumed)),
          ];
        }
        break;
      case ThumperPower.on:
        {
          return [
            _button(Icons.replay, null),
            _button(Icons.skip_next, null),
            _button(Icons.pause, () => bloc.add(ThumperEvent.paused)),
          ];
        }
        break;
    }
    return [];
  }

  IconButton _button(IconData d, void Function() f) => IconButton(
        color: onColor,
        disabledColor: offColor,
        icon: Icon(d),
        onPressed: f,
      );
}
