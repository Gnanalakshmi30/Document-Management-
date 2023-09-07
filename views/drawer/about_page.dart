import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mailto/mailto.dart';
import 'package:unicons/unicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:USB_Share/Util/palette.dart';

import '../../components/constants.dart';
import '../../components/dialogs.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('About'),
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Credits'),
            leading: SvgPicture.asset('assets/icons/credits.svg',
                color: Colors.amberAccent),
            onTap: () {
              credits(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.email_rounded,
              color: Colors.redAccent,
            ),
            onTap: () {
              var url = Mailto(
                to: ['photon19dev@gmail.com'],
              ).toString();
              launchUrl(Uri.parse(url));
            },
            title: const Text('Email'),
            subtitle: const Text('photon19dev@gmail.com'),
          ),
          ListTile(
            leading: const Icon(UniconsLine.twitter, color: Colors.blueAccent),
            onTap: () {
              launchUrl(Uri.parse('https://twitter.com/AbhilashHegde9'));
            },
            title: const Text('Twitter'),
            subtitle: const Text('https://twitter.com/AbhilashHegde9'),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
                child: Text('Please consider supporting this project 💙')),
          ),
          InkWell(
            onTap: () async {
              try {
                await launchUrl(
                    Uri.parse('https://www.buymeacoffee.com/abhi1.6180'));
              } catch (_) {}
            },
            child: SvgPicture.asset(
              'assets/icons/bmc-button.svg',
              width: MediaQuery.of(context).size.width / 2,
            ),
          ),
        ],
      ),
    );
  }
}
