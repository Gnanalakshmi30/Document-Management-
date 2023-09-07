import 'dart:async';

import 'package:rxdart/rxdart.dart';

class DashboardBloc {
  final PublishSubject<String> _progressPercentage = PublishSubject<String>();
  Stream<String> get progressPercentageStream => _progressPercentage.stream;

  setProgressPercentage(String data) {
    _progressPercentage.add(data);
  }

  final PublishSubject<bool> _iconUpdate = PublishSubject<bool>();
  Stream<bool> get iconProgressStream => _iconUpdate.stream;

  setProgressIconStatus(bool res) {
    _iconUpdate.add(res);
  }

  final PublishSubject<String> _progressText = PublishSubject<String>();
  Stream<String> get progressTextStream => _progressText.stream;

  setProgressText(String data) {
    _progressText.add(data);
  }

  final PublishSubject<bool> _buttonUpdate = PublishSubject<bool>();
  Stream<bool> get buttonProgressStream => _buttonUpdate.stream;

  setProgressButtonStatus(bool res) {
    _buttonUpdate.add(res);
  }

  final PublishSubject<String> _imageText = PublishSubject<String>();
  Stream<String> get imageFileTextStream => _imageText.stream;

  setImageFileText(String res) {
    _imageText.add(res);
  }

  final PublishSubject<String> _androidFileCount = PublishSubject<String>();
  Stream<String> get androidFileCountStream => _androidFileCount.stream;

  setAndroidFileCount(String data) {
    _androidFileCount.add(data);
  }

  final PublishSubject<String> _windowsFileCount = PublishSubject<String>();
  Stream<String> get windowsFileCountStream => _windowsFileCount.stream;

  setWindowsFileCount(String data) {
    _windowsFileCount.add(data);
  }

  final PublishSubject<int> _stepperIndexCount = PublishSubject<int>();
  Stream<int> get stepperIndexStream => _stepperIndexCount.stream;

  setStepperIndexCount(int data) {
    _stepperIndexCount.add(data);
  }

  final PublishSubject<String> _estimatedTimeCount = PublishSubject<String>();
  Stream<String> get estimatedTimeCountStream => _estimatedTimeCount.stream;

  setestimatedTimeCount(String data) {
    _estimatedTimeCount.add(data);
  }
}

final dashboardBloc = DashboardBloc();
