import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_pwa_wrapper/push_notifications_manager.dart';

class SETTINGS {
  static const title = 'Innform';
  static const url = 'https://app.innform.io/'; // test dev
  static const allowedOrigins = ["innform.io", "intersport.de", "intersportakademie.at", "serverhero.de", "lowa.de", "sebazzo.com"];
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
    cookieDomain ??= Uri.parse(SETTINGS.url).host;
    bool tempAllowRedirect = false;

    /**
     * How to use in JS:
     * function setPushToken(token) { ... } // returns the device token
     * Notification.requestPermission()
     */
    void javaScriptFunction (JavaScriptMessage message) async {
      if(message.message == 'getPushToken') {
        var pnm = PushNotificationsManager.getInstance();
        if(SETTINGS.shouldAskForPushPermission) {
          await pnm.requestPermission();
        }
        final pushToken = await pnm.getToken();
        final script = "setPushToken(\"$pushToken\")";
        webviewController.runJavaScript(script);
      }
    }

    launchURL(Uri uri) async {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }

    webviewController = WebViewController()
      ..loadRequest(Uri.parse(SETTINGS.url))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('flutterChannel', onMessageReceived: javaScriptFunction)
      ..setUserAgent(SETTINGS.userAgent)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url)  {
          webviewController.runJavaScript("""
            window.Notification = {
              requestPermission: (callback) => {
                window.flutterChannel.postMessage('getPushToken');
                return callback ? callback('granted') : true;
              }
            };
          """);
        },
        onNavigationRequest: (NavigationRequest request) {
          // debugPrint('onNavigationRequest ${request.url} ${request.isMainFrame}');
          Uri uri = Uri.parse(request.url);
          bool allow = !request.isMainFrame;
          if(!allow) {
            // starts SSO login
            if(uri.host == "sso.innform.io" || uri.host == "auth.innform.io" || uri.host.endsWith("auth0.com")) {
              tempAllowRedirect = true;
            }

            bool onOrigins = false;
            for(String allowedOrigin in SETTINGS.allowedOrigins) {
              if(uri.host.endsWith(allowedOrigin)) {
                onOrigins = true;
                break;
              }
            }
            if(tempAllowRedirect && onOrigins && uri.host != "sso.innform.io" && uri.host != "auth.innform.io") {
              tempAllowRedirect = false;
            }
            allow = onOrigins || tempAllowRedirect;
          }
          if (allow) {
            return NavigationDecision.navigate;
          }
          launchURL(uri);
          return NavigationDecision.prevent;
        }),
      );

    PushNotificationsManager.getInstance().init(webviewController, SETTINGS.shouldAskForPushPermission);

    return WebViewWidget(controller: webviewController);
  }

  _launchURL(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
