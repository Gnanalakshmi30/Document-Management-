// ignore_for_file: prefer_const_constructors

import 'package:USB_Share/AddImage/Page/android_addimage_page.dart';
import 'package:USB_Share/AddImage/Page/android_view_watermark_image.dart';
import 'package:USB_Share/Dashboard/Page/android_Dashboard_page.dart';
import 'package:USB_Share/Project/Page/android_subfolder_page.dart';
import 'package:USB_Share/Splash/Page/LicenseExpiredPage.dart';
import 'package:USB_Share/Template/Page/androidGenerateReport.dart';
import 'package:USB_Share/Template/Page/createTemplate.dart';
import 'package:USB_Share/Template/Page/generateReport.dart';
import 'package:USB_Share/Template/Page/tableView.dart';
import 'package:USB_Share/Template/Page/templatePage.dart';
import 'package:flutter/material.dart';
import 'package:USB_Share/AddImage/Page/addimage_page.dart';
import 'package:USB_Share/AddImage/Page/photo_view_image.dart';
import 'package:USB_Share/AddImage/Page/view_watermark_image.dart';
import 'package:USB_Share/Configuration/config_page.dart';
import 'package:USB_Share/Dashboard/Page/dashboard_page.dart';
import 'package:USB_Share/Project/Page/project_folder_page.dart';
import 'package:USB_Share/Project/Page/subfolder_page.dart';
import 'package:USB_Share/Splash/Page/splashPage.dart';
import 'package:USB_Share/app.dart';
import 'package:USB_Share/views/apps_list.dart';
import 'package:USB_Share/views/drawer/history.dart';
import 'package:USB_Share/views/receive_ui/manual_scan.dart';
import 'package:USB_Share/views/share_ui/share_page.dart';

import '../Template/Page/androidTableView.dart';

class PageRouter {
  static const String splash = '/';
  static const String projectPage = '/projectPage';
  static const String subFolderPage = '/subFolderPage';
  static const String androidSubFolderPage = '/AndroidSubFolderPage';
  static const String addImagePage = '/addImagePage';
  static const String androidaddImagePage = '/AndroidaddImagePage';
  static const String home = '/home';
  static const String sharepage = '/sharepage';
  static const String receivepage = '/receivepage';
  static const String history = '/history';
  static const String apps = '/apps';
  static const String viewWatermarkImage = '/viewWatermark';
  static const String androidViewWaterMark = '/androidViewWaterMark';
  static const String photoViewImage = '/photoViewImage';
  static const String dashboard = '/dashboard';
  static const String configuration = '/configuration';
  static const String template = '/template';
  static const String windowsEditor = '/windowsEditor';
  static const String generateReport = '/generateReport';
  static const String tableWebview = '/tableWebview';
  static const String androidDashboardPage = '/AndroidDashboardPage';
  static const String androidGenerateReport = '/AndroidGenerateReport';
  static const String licenseExpied = '/licenseExpied';

  static const String androidTableView = '/AndroidTableView';
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case PageRouter.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case PageRouter.projectPage:
        return MaterialPageRoute(builder: (_) => ProjectPage());
      case PageRouter.subFolderPage:
        if (args is Map) {
          return CustomPageRoute(
              child: SubFolderPage(
            projName: args["projName"],
          ));
        } else {
          return _errorRoute();
        }
      case PageRouter.androidSubFolderPage:
        if (args is Map) {
          return CustomPageRoute(
              child: AndroidSubFolderPage(
            projName: args["projName"],
          ));
        } else {
          return _errorRoute();
        }
      case PageRouter.addImagePage:
        if (args is Map) {
          return CustomPageRoute(
              child: AddImagePage(
            projName: args["projName"],
            folderName: args["folderName"],
            isNewImageAdded: args["isNewImageAdded"],
          ));
        } else {
          return _errorRoute();
        }
      case PageRouter.androidaddImagePage:
        if (args is Map) {
          return CustomPageRoute(
              child: AndroidaddImagePage(
            projName: args["projName"],
            folderName: args["folderName"],
            isNewImageAdded: args["isNewImageAdded"],
          ));
        } else {
          return _errorRoute();
        }
      case PageRouter.home:
        return MaterialPageRoute(builder: (_) => const App());
      case PageRouter.sharepage:
        return MaterialPageRoute(builder: (_) => const SharePage());
      case PageRouter.receivepage:
        return MaterialPageRoute(builder: (_) => const ReceivePage());
      case PageRouter.history:
        return MaterialPageRoute(builder: (_) => const HistoryPage());
      case PageRouter.apps:
        return MaterialPageRoute(builder: (_) => const AppsList());
      case PageRouter.androidDashboardPage:
        return MaterialPageRoute(builder: (_) => const AndroidDashboardPage());
      case PageRouter.androidGenerateReport:
        return MaterialPageRoute(builder: (_) => const AndroidGenerateReport());
      case PageRouter.viewWatermarkImage:
        if (args is Map) {
          return CustomPageRoute(
              child: ViewWaterMark(
            projName: args["projName"],
            image: args["image"],
            folderName: args["folderName"],
            isWithoutSubfolder: args["isWithoutSubfolder"],
          ));
        } else {
          return _errorRoute();
        }
      case PageRouter.licenseExpied:
        return MaterialPageRoute(builder: (_) => const LicenseExpired());
      case PageRouter.androidViewWaterMark:
        if (args is Map) {
          return CustomPageRoute(
              child: AndroidViewWaterMark(
            projName: args["projName"],
            image: args["image"],
            folderName: args["folderName"],
            isWithoutSubfolder: args["isWithoutSubfolder"],
          ));
        } else {
          return _errorRoute();
        }
      case PageRouter.photoViewImage:
        if (args is Map) {
          return CustomPageRoute(
              child: PhotoViewImage(
            image: args["image"],
          ));
        } else {
          return _errorRoute();
        }
      case PageRouter.dashboard:
        if (args is Map) {
          return CustomPageRoute(
              child: DashboardPage(
            index: args["index"],
            newProjCreated: args["newProjCreated"],
          ));
        } else {
          return _errorRoute();
        }

      case PageRouter.configuration:
        return MaterialPageRoute(builder: (_) => const ConfigurationPage());
      case PageRouter.template:
        return MaterialPageRoute(builder: (_) => const TemplatePage());
      case PageRouter.windowsEditor:
        if (args is Map) {
          return CustomPageRoute(
              child: WindowsEditor(
            templateName: args["templateName"],
            isFormGR: args["isFormGR"],
            projectNo: args["projectNo"],
            categoryId: args["categoryId"],
            isEditTemp: args["isEditTemp"],
          ));
        } else {
          return _errorRoute();
        }
      case PageRouter.tableWebview:
        if (args is Map) {
          return CustomPageRoute(
              child: TableView(
                  htmlString: args["htmlString"],
                  tableContentFilePath: args["tableContentFilePath"],
                  templateFilePath: args["templateFilePath"],
                  actualtemplatePath: args["actualtemplatePath"],
                  keywordList: args["keywordList"],
                  keyContentPath: args["keyContentPath"]));
        } else {
          return _errorRoute();
        }
      case PageRouter.androidTableView:
        if (args is Map) {
          return CustomPageRoute(
              child: AndroidTableView(
            htmlString: args["htmlString"],
            keywordList: args["keywordList"],
            tableContentFilePath: args["tableContentFilePath"],
            keyContentPath: args["keyContentPath"],
            // dirPath: args["dirPath"],
          ));
        } else {
          return _errorRoute();
        }
      case PageRouter.generateReport:
        return MaterialPageRoute(builder: (_) => const GenerateReport());

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) => const ProjectPage());
  }
}

class CustomPageRoute extends PageRouteBuilder {
  final Widget child;
  CustomPageRoute({required this.child})
      : super(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) => child);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(animation),
        child: child,
      );
}
