import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thumper/data/fruit.dart';
import 'package:thumper/thumper.dart';

void main() => runApp(DemoApp());

class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Thumper Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: _MyScaffold(),
      );
}

class _MyScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext c) => BlocProvider(
        create: (context) =>
            ThumperBloc<Fruit>.fromIterable(List.from(Fruit.values)),
        child: Scaffold(
          backgroundColor: Colors.black,
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
                        _textElement(state.thing.toString().substring(6)),
                  ),
                ),
              ),
              Thumper<Fruit>(),
            ],
          ),
        ),
      );

  Widget _textElement(String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 64,
          color: Colors.greenAccent,
        ));
  }
}
