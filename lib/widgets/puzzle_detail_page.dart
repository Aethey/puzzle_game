import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'game_page.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({this.includeMarkAsDoneButton = true, this.bytes});

  final bool includeMarkAsDoneButton;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: buildBody(context, size),
    );
  }

  Column buildBody(BuildContext context, Size size) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 40),
          height: size.width,
          width: size.width,
          child: Image.memory(
            bytes,
            fit: BoxFit.fill,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.done),
          onPressed: () {
            Navigator.pop(context, true);
          },
//            tooltip: 'Mark as done',
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  startGame(context);
                },
                child: Text('mission start'),
              ),
              const SizedBox(height: 10),
              Text(
                '_loremIpsumParagraph',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                      color: Colors.black54,
                      height: 1.5,
                      fontSize: 16.0,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> startGame(BuildContext context) async {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (context) =>
                GamePage(MediaQuery.of(context).size, bytes, 3)));
  }
}
