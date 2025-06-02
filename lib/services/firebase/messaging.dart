import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {

  final FirebaseMessaging _msgService = FirebaseMessaging.instance;

  // Ajoutez ce getter public
  FirebaseMessaging get msgService => _msgService;

  initFCM () async {

    await msgService.requestPermission();

    var token = await msgService.getToken();

    print ("Token: $token");

    FirebaseMessaging.onBackgroundMessage(handleNotification);
    FirebaseMessaging.onMessage.listen(handleNotification);
  }

}

Future <void> handleNotification(RemoteMessage msg)async {

}