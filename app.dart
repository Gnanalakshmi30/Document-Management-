import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:USB_Share/views/home/widescreen_home.dart';
import 'views/home/mobile_home.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  TextEditingController usernameController = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  Box box = Hive.box('appData');
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Photo App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Center(
        child: size.width > 720 ? const WidescreenHome() : const MobileHome(),
      ),
    );
  }
}
