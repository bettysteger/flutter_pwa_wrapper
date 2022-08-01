import 'package:flutter/material.dart';
import 'package:webviewx/webviewx.dart';

class SETTINGS {
  static const title = 'Flutter PWA Wrapper';
  static const url = 'https://news.ycombinator.com/';
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: SETTINGS.title,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewXController webviewController;

  Size get screenSize => MediaQuery.of(context).size;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewX(
        key: const ValueKey('webviewx'),
        initialContent: SETTINGS.url,
        // initialSourceType: SourceType.urlBypass,
        height: screenSize.height,
        width: screenSize.width,
        onWebViewCreated: (controller) async {
          webviewController = controller;
          // webviewController.callJsMethod('testPlatformIndependentMethod', []);
          // final result = await webviewController.evalRawJavascript(
          //   'localStorage.setItem("isWKWebView", true)',
          //   inGlobalContext: true,
          // );
          // debugPrint(result);
        },
        jsContent: const {
          EmbeddedJsContent(
            js: "alert('blubb'); localStorage.setItem('isWKWebView', true);",
            // webJs:
            //     "function testPlatformSpecificMethod(msg) { TestDartCallback('Web callback says: ' + msg) }",
            // mobileJs:
            //     "function testPlatformSpecificMethod(msg) { TestDartCallback.postMessage('Mobile callback says: ' + msg) }",
          ),
        },
        // dartCallBacks: {
        //   DartCallback(
        //     name: 'TestDartCallback',
        //     callBack: (msg) => showSnackBar(msg.toString(), context),
        //   )
        // },
        webSpecificParams: const WebSpecificParams(
          printDebugInfo: true,
        ),
        mobileSpecificParams: const MobileSpecificParams(
          androidEnableHybridComposition: true,
        ),
        navigationDelegate: (navigation) {
          debugPrint(navigation.content.sourceType.toString());
          return NavigationDecision.navigate;
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    webviewController.dispose();
    super.dispose();
  }
}
