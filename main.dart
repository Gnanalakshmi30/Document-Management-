import 'dart:io';
import 'package:USB_Share/Util/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/controllers/controllers.dart';
import 'package:USB_Share/methods/share_intent.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

final nav = GlobalKey<NavigatorState>();
FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
void main() async {
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init((await getApplicationDocumentsDirectory()).path);
  await Hive.openBox('appData');
  Box box = Hive.box('appData');
  box.get('avatarPath') ?? box.put('avatarPath', 'assets/avatars/1.png');
  box.get('username') ?? box.put('username', '${Platform.localHostname} user');
  box.get('queryPackages') ?? box.put('queryPackages', false);
  GetIt getIt = GetIt.instance;

  SharedPreferences prefInst = await SharedPreferences.getInstance();
  prefInst.get('isIntroRead') ?? prefInst.setBool('isIntroRead', false);
  prefInst.get('isDarkTheme') ?? prefInst.setBool('isDarkTheme', true);
  getIt.registerSingleton<PercentageController>(PercentageController());
  getIt.registerSingleton<ReceiverDataController>(ReceiverDataController());

  if (Platform.isAndroid) {
    await handleSharingIntent();
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return OrientationBuilder(builder: (context, orientation) {
          Sizing().init(constraints, orientation);
          return MaterialApp(
            theme: ThemeData.light().copyWith(
              primaryColor: primaryColor,
              scaffoldBackgroundColor: Colors.white,
            ),
            navigatorKey: nav,
            debugShowCheckedModeBanner: false,
            initialRoute: PageRouter.splash,
            onGenerateRoute: RouteGenerator.generateRoute,
          );
        });
      },
    );
  }
}
