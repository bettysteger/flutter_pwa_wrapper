import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter_pwa_wrapper/push_notifications_manager.dart';

class SETTINGS {
  static const title = 'Innform';
  static const url = 'https://app.innform.io/'; // test dev
  static const allowedOrigins = ["innform.io", "feintool.com", "intersport.de", "intersportakademie.at", "serverhero.de", "sabu-wissenswelt.de", "swissbiomechanics-wissenswelt.ch", "anwr-wissenswelt.com", "bilthouse.com", "learningkw.com", "influencer.com", "kurtzersa.de", "emilabs.ai", "finmatics.com", "zusa-fachlehrgang.ch", "royaltap.live", "sportscheck.com", "rewe-dortmund.de", "kramer-schuhe-gruppe.de"];
  static const newTabs = ["help.innform.io"];
  static const cookieDomain = null; // only necessary if you are using a subdomain and want it on the top-level domain

  static const shouldAskForPushPermission = true;
  // set userAgent to prevent 403 Google 'Error: Disallowed_Useragent'
  // @see https://stackoverflow.com/a/69342626/595152
  static const userAgent = "Mozilla/5.0 (iPhone14,6; U; CPU iPhone OS 15_4 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/19E241 Safari/602.1";
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

    /// How to use in JS:
    ///
    /// function setPushToken(token) { ... } // returns the device token
    /// Notification.requestPermission()
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

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    webviewController = WebViewController.fromPlatformCreationParams(params)
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
              if(uri.host.endsWith(allowedOrigin) && !SETTINGS.newTabs.contains(uri.host)) {
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
}
