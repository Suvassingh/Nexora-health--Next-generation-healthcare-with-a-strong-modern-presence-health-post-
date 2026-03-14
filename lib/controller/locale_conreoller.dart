import 'package:get/get.dart';

class LocaleController extends GetxController {
  static LocaleController get to => Get.find();

  final RxString locale = 'en'.obs; // 'en' | 'np'

  bool get isNepali => locale.value == 'np';

  void setLocale(String l) {
    locale.value = l;
  }
}
