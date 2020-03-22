import 'package:flutter/material.dart';
import 'package:thumper/miscdata/fruit.dart';
import 'package:thumper/thumper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() => runApp(ThumperApp());

class ThumperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) =>
            ThumperBloc<Fruit>.fromIterable(List.from(Fruit.values)),
        child: MaterialApp(
          title: 'Thumper Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: _MyScaffold(),
        ),
      );
}

class _MyScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.blue.shade400,
        appBar: AppBar(
          title: Text('Fruit Thumper'),
          leading: Icon(Icons.menu),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Center(
                child: BlocBuilder<ThumperBloc<Fruit>, ThumperState>(
                  builder: (context, state) =>
                      _textElement(state.thing.toString()),
                ),
              ),
            ),
            Expanded( child: Thumper<Fruit>()),
          ],
        ),
      );

  Widget _textElement(String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 18,
          color: Colors.greenAccent,
        ));
  }
}
