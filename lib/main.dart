import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SETTINGS {
  static const title = 'Flutter PWA Wrapper';
  static const url = 'https://bettysteger.com/flutter_pwa_wrapper/demo/'; // http://localhost:8000/ test dev
  static const cookieDomain = null; // only necessary if you are using a subdomain and want it on the top-level domain
  // set userAgent to prevent 403 Google 'Error: Disallowed_Useragent'
  // @see https://stackoverflow.com/a/69342626/595152
  static const userAgent = "Mozilla/5.0 (Linux; Android 8.0; Pixel 2 Build/OPD3.170816.012) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Mobile Safari/537.36";
}

void main() {
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

    return WebView(
      initialUrl: SETTINGS.url,
      javascriptMode: JavascriptMode.unrestricted,
      initialCookies: [WebViewCookie(name: 'isNative', value: 'true', domain: cookieDomain)],
      onWebViewCreated: (controller) {
        webviewController = controller;
      },
      // onPageFinished: (url) => webviewController.runJavascript('localStorage.setItem("isNative", true)'),
      navigationDelegate: (navigation) {
        debugPrint('navigationDelegate ${navigation.url}');
        return NavigationDecision.navigate;
      },
      userAgent: SETTINGS.userAgent,
    );
  }
}
