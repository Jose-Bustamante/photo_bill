import 'package:flutter/material.dart';

class MainView extends StatelessWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Main View'),
        ),
        body: Container(
          alignment: Alignment.center,
          color: Color(0xff258DED),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, 'camera'),
                      child: Text('Save bill')),
                  ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, 'bills'),
                      child: Text('Show saved Bills'))
                ],
              )
            ],
          ),
        ));
  }
}
