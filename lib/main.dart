import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_pwa_wrapper/push_notifications_manager.dart';

class SETTINGS {
  static const title = 'Innform [Staging]';
  static const url = 'https://stagingapp.innform.io/'; // test dev
  static const allowedOrigins = ["innform.io"];
  static const cookieDomain = null; // only necessary if you are using a subdomain and want it on the top-level domain

  static const shouldAskForPushPermission = true;
  // set userAgent to prevent 403 Google 'Error: Disallowed_Useragent'
  // @see https://stackoverflow.com/a/69342626/595152
  static const userAgent = "Mozilla/5.0 (Linux; Android 8.0; Pixel 2 Build/OPD3.170816.012) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Mobile Safari/537.36";
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    cookieDomain ??= SETTINGS.url.replaceFirst(RegExp('https?://'), '').split('/')[0];

    /**
     * How to use in JS:
     * function setPushToken(token) { ... } // returns the device token
     * Notification.requestPermission()
     */
    JavascriptChannel channel = JavascriptChannel(
      name: 'flutterChannel',
      onMessageReceived: (JavascriptMessage message) async {
        if(message.message == 'getPushToken') {
          var pnm = PushNotificationsManager.getInstance();
          if(SETTINGS.shouldAskForPushPermission) {
            await pnm.requestPermission();
          }
          final token = await pnm.getToken();
          webviewController.runJavascript("setPushToken(\"$token\")");
        }
      },
    );

    return WebView(
      initialUrl: SETTINGS.url,
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: {channel},
      initialCookies: [WebViewCookie(name: 'isNative', value: 'true', domain: cookieDomain)],
      onWebViewCreated: (controller) async {
        webviewController = controller;
        var pnm = PushNotificationsManager.getInstance();
        await pnm.init(webviewController, SETTINGS.shouldAskForPushPermission);
        pnm.onNewToken.listen((token) {
          webviewController.runJavascript("setPushToken(\"$token\")");
        });
      },
      onPageFinished: (url) {
        webviewController.runJavascript("""
          window.Notification = {
            requestPermission: (callback) => {
              window.flutterChannel.postMessage('getPushToken');
              return callback ? callback('granted') : true;
            }
          };
        """);
      },
      navigationDelegate: (navigation) {
        // debugPrint('navigationDelegate ${navigation.url} ${navigation.isForMainFrame}');
        Uri uri = Uri.parse(navigation.url);
        bool allow = !navigation.isForMainFrame;
        if(!allow) {
          for(String allowedOrigin in SETTINGS.allowedOrigins) {
            if(uri.host.endsWith(allowedOrigin)) {
              allow = true;
              break;
            }
          }
        }
        if (allow) {
          return NavigationDecision.navigate;
        }
        _launchURL(uri);
        return NavigationDecision.prevent;
      },
      userAgent: SETTINGS.userAgent,
    );
  }

  _launchURL(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
