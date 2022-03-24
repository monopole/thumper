import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thumper_bloc/thumper_bloc.dart';

// ignore_for_file: diagnostic_describe_all_properties
// ignore_for_file: avoid_redundant_argument_values

/// A Thumper<E> widget is a row of controls associated with a ThumperBloc<E>,
/// which in turn contains an Iterable<E>.
///
/// Controls include reset, forward step, play, pause, and frequency
/// selection.
///
/// There's no backward step, as the Iterator interface (wisely) doesn't
/// require a reversible process.
///
/// This widget doesn't show E or make an calls on E, but must get an
/// instance of ThumperBloc<E> from the context (hence the parameterization).
///
/// This widget has a fixed size (like an Icon).
///
/// The term 'thumper' is from Dune by Frank Herbert.
@immutable
class Thumper<E> extends StatelessWidget {
  /// Make a [Thumper].
  const Thumper({
    Key? key,
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
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints.tightFor(
            width: width.toDouble(), height: height.toDouble()),
        child: _controlRow(context),
      );

  Widget _controlRow(BuildContext c) {
    final bloc = BlocProvider.of<ThumperBloc<E>>(c);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      BlocBuilder<ThumperBloc<E>, ThumperState<E>>(
        buildWhen: (previousState, incomingState) =>
            incomingState.power != previousState.power,
        builder: (context, state) => Row(
          children: _buttonList(bloc),
        ),
      ),
      BlocBuilder<ThumperBloc<E>, ThumperState<E>>(
        buildWhen: (previousState, incomingState) =>
            incomingState.frequency != previousState.frequency,
        builder: (context, state) => _themedSlider(context, bloc),
      ),
    ]);
  }

  Widget _themedSlider(BuildContext c, ThumperBloc<E> bloc) => SliderTheme(
        data: SliderTheme.of(c).copyWith(
          trackHeight: 4,
          thumbColor: onColor,
          overlayColor: Colors.purple.withAlpha(32),
          // TODO: figure out why making these shapes 'const'
          // seems to dramatically slow things down
          // ignore: prefer_const_constructors
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
          // ignore: prefer_const_constructors
          overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
        ),
        child: _rawSlider(bloc),
      );

  Widget _rawSlider(ThumperBloc<E> bloc) => Slider(
        value: bloc.state.frequency.unitInterval,
        min: 0, // Default values for min and max - but being explicit as
        max: 1, // this particular range setting is crucial.
        activeColor: onColor,
        divisions: bloc.numDivisions,
        onChanged: (s) => bloc.reactToFrequencyValue(s),
      );

  List<Widget> _buttonList(ThumperBloc<E> bloc) {
    switch (bloc.state.power) {
      case Power.reset:
        {
          return [
            _button(Icons.replay, null),
            _button(
                Icons.skip_next, () => bloc.add(ThumperEventThumpedManually())),
            _button(Icons.play_arrow, () => bloc.add(ThumperEventResumed())),
          ];
        }
      case Power.idle:
        {
          return [
            _button(Icons.replay, () => bloc.add(ThumperEventRewound())),
            _button(Icons.skip_next,
                () => bloc.add(ThumperEventThumpedAutomatically())),
            _button(Icons.play_arrow, () => bloc.add(ThumperEventResumed())),
          ];
        }
      case Power.running:
        {
          return [
            _button(Icons.replay, null),
            _button(Icons.skip_next, null),
            _button(Icons.pause, () => bloc.add(ThumperEventPaused())),
          ];
        }
    }
  }

  IconButton _button(IconData d, void Function() ?f) => IconButton(
        color: onColor,
        disabledColor: offColor,
        icon: Icon(d),
        onPressed: f,
      );
}
