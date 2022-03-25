import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thumper/thumper.dart';

void main() => runApp(DemoApp());

/// A toy app to demonstrate Thumper use.
class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Thumper Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Fruit Thumper'),
          leading: Icon(Icons.menu),
        ),
        body: ThumperDemo()),
  );
}

/// A demo widget containing a [Thumper] and associated [ThumperBloc].
///
/// The demo widget is a centered text widget showing a [Fruit] name
/// above a Thumper widget that provides iteration controls through
/// a [Fruit] list.
///
/// The [Fruit] comes from a bloc state, so the text widget must be
/// wrapped in a [BlocBuilder] to make the bloc state available to it.
///
/// Above both the Thumper and any use of ThumperBloc state, a
/// [BlocProvider] is needed to 1) construct a ThumperBloc instance,
/// 2) make bloc states available to [BlocBuilder]s in the widget
/// tree below the [BlocProvider], and 3) dispose of the bloc and its
/// associated streams when the encapsulating widget (in this
/// case [ThumperDemo]) is disposed.
class ThumperDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) =>
    ThumperBloc<Fruit>.fromIterable(List.from(Fruit.values)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Center(
            child: BlocBuilder<ThumperBloc<Fruit>, ThumperState<Fruit>>(
              builder: (ctx, state) =>
                  _textElement(state.thing.toString().substring(6)),
            ),
          ),
        ),
        const Thumper<Fruit>(),
      ],
    ),
  );

  Widget _textElement(String text) => Text(text,
      style: TextStyle(
        fontSize: 64,
        color: Colors.greenAccent,
      ));
}