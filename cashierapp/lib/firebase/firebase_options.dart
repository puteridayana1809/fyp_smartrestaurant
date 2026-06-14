// Manually configured Firebase options for project "kedai-bihun-selambak".
// iOS values come from ios/Runner/GoogleService-Info.plist.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return const FirebaseOptions(
        apiKey: "AIzaSyA8YIGvs9YDO81XS0NH8pxhaErdRlapgfE",
        appId: "1:912675316718:ios:e7a1e3e33ed86da2af64ff",
        messagingSenderId: "912675316718",
        projectId: "kedai-bihun-selambak",
        storageBucket: "kedai-bihun-selambak.firebasestorage.app",
        databaseURL: "https://kedai-bihun-selambak-default-rtdb.asia-southeast1.firebasedatabase.app",
        iosBundleId: "com.bihunsupdagingselambak.cashierapp",
      );
    }

    // TODO: Replace with the Android app's config from
    // android/app/google-services.json once registered in the
    // "kedai-bihun-selambak" Firebase project for a proper "android:" appId.
    return const FirebaseOptions(
      apiKey: "AIzaSyAJLpR4IgLaTYApv5t5Xx4LjtKey4hvk2A",
      appId: "1:912675316718:web:9e4c950d1e1287c0af64ff",
      messagingSenderId: "912675316718",
      projectId: "kedai-bihun-selambak",
      storageBucket: "kedai-bihun-selambak.firebasestorage.app",
      databaseURL: "https://kedai-bihun-selambak-default-rtdb.asia-southeast1.firebasedatabase.app",
    );
  }
}
