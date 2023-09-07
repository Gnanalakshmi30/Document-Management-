import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:file_picker/file_picker.dart';
import "package:flutter/material.dart";
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:USB_Share/views/drawer/edit_profile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences pref;
  _future() async {
    pref = await SharedPreferences.getInstance();
    return await FileMethods.getSaveDirectory();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text("Settings"),
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: FutureBuilder(
          future: _future(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.done) {
              return Center(
                child: Container(
                  width: w > 720 ? w / 1.4 : w,
                  child: Center(
                    child: ListView(
                      children: [
                        ListTile(
                          title: const Text("Save path"),
                          subtitle: Text(snap.data.toString()),
                          trailing: IconButton(
                            onPressed: () async {
                              var resp =
                                  await FilePicker.platform.getDirectoryPath();
                              setState(() {
                                if (resp != null) {
                                  FileMethods.editDirectoryPath(resp);
                                }
                              });
                            },
                            icon: Icon(
                              Icons.edit_rounded,
                              size: w > 720 ? 38 : 24,
                              semanticLabel: 'Edit path',
                            ),
                          ),
                        ),
                        ListTile(
                          title: const Text('Toggle theme'),
                          trailing: Switch(
                            value: pref.getBool('isDarkTheme')!,
                            onChanged: (val) {
                              setState(() {
                                if (pref.getBool('isDarkTheme') == false) {
                                  AdaptiveTheme.of(context).setDark();
                                  pref.setBool('isDarkTheme', true);
                                } else {
                                  AdaptiveTheme.of(context).setLight();
                                  pref.setBool('isDarkTheme', false);
                                }
                              });
                            },
                          ),
                        ),
                        ListTile(
                          trailing: IconButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                return const EditProfilePage();
                              }));
                            },
                            icon: SvgPicture.asset(
                              'assets/icons/profile_edit.svg',
                              color: Colors.black,
                            ),
                          ),
                          title: const Text('Edit profile'),
                        )
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ));
  }
}
