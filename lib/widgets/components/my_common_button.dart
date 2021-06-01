import 'package:flutter/material.dart';
import 'package:photopuzzle/common/constants.dart';


class MyCommonButton extends StatelessWidget {
  const MyCommonButton({
    Key key,
    @required this.text,
    this.press,
  }) : super(key: key);

  final String text;
  final Function press;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Container(
      width: size.width / 3,
      child: TextButton(
          onPressed: () => press(),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(yTextLightColor),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25))))),
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .headline5
                .copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          )),
    );
  }
}
