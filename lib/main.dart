import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_pwa_wrapper/push_notifications_manager.dart';

class SETTINGS {
  static const title = 'Flutter PWA Wrapper';
  static const url = 'https://bettysteger.com/flutter_pwa_wrapper/demo/auto-marketing.html'; // 'http://localhost:8887/'; // test dev
  static const cookieDomain = null; // only necessary if you are using a subdomain and want it on the top-level domain

  // set userAgent to prevent 403 Google 'Error: Disallowed_Useragent'
  // @see https://stackoverflow.com/a/69342626/595152
  static const userAgent = "Mozilla/5.0 (Linux; Android 8.0; Pixel 2 Build/OPD3.170816.012) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Mobile Safari/537.36";
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: SETTINGS.title,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewController webviewController;

  @override
  Widget build(BuildContext context) {
    String? cookieDomain = SETTINGS.cookieDomain;
    cookieDomain ??= Uri.parse(SETTINGS.url).host;

    launchURL(Uri uri) async {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }

    webviewController = WebViewController()
      ..loadRequest(Uri.parse(SETTINGS.url))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(SETTINGS.userAgent)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) async {
          var pnm = PushNotificationsManager.getInstance();
          final pushToken = await pnm.getToken();
          webviewController.runJavaScript("setPushToken(\"$pushToken\")");
          // await pnm.subscribeToMarketing();
        },
        onNavigationRequest: (NavigationRequest request) {
          // debugPrint('onNavigationRequest ${request.url} ${request.isMainFrame}');
          Uri uri = Uri.parse(request.url);
          if (!request.isMainFrame || uri.host == Uri.parse(SETTINGS.url).host) {
            return NavigationDecision.navigate;
          }
          launchURL(uri);
          return NavigationDecision.prevent;
        }),
      );

    PushNotificationsManager.getInstance().init(webviewController);

    return WebViewWidget(controller: webviewController);
  }
}
