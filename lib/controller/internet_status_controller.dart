import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

// class ConnectivityController extends GetxController {
//   late Rx<ConnectivityResult> connectionType;
//   @override
//   void onInit() {
//     super.onInit();
//     connectionType = ConnectivityResult.none.obs;
//     Connectivity().onConnectivityChanged.listen((result) {
//       connectionType.value = result.first;
//     });
//   }
// }

class ConnectivityController extends GetxController {
  final connectionType = ConnectivityResult.none.obs;

  @override
  void onInit() {
    super.onInit();
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        connectionType.value = results.first;
      }
    });
  }
}
