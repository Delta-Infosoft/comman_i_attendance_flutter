import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../flavor_config.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import '../../constant/local_db/local_db.dart';

class IerpHoWebView extends StatefulWidget {
  const IerpHoWebView({super.key});

  @override
  State<IerpHoWebView> createState() => _IerpHoWebViewState();
}

class _IerpHoWebViewState extends State<IerpHoWebView> {
  String? savedIp;
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final ip = LocalDbController.to.storage.read("IP_Address");

    if (ip == null) return;

    savedIp = ip;

    final String finalUrl = "http://$savedIp${ApiUrl.iERPHoWebLogin}";

    _controller = WebViewController()
      ..setUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1")
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
              NavigationDelegate(
                onNavigationRequest: (request) async {
                  // Allow all navigation
                  return NavigationDecision.navigate;
                },
                onPageStarted: (_) {
                  setState(() => isLoading = true);
                },
                onPageFinished: (_) async {
                  setState(() => isLoading = false);

                  await _controller.runJavaScript("""
    (function() {
      // 1. Force CSS to allow pointer events on everything
      var style = document.createElement('style');
      style.innerHTML = '* { cursor: pointer !important; pointer-events: auto !important; -webkit-user-select: auto !important; }';
      document.head.appendChild(style);

      // 2. Add an empty click listener to all elements (fixes iOS 'clickable' bug)
      var allElements = document.querySelectorAll('*');
      for (var i = 0; i < allElements.length; i++) {
        allElements[i].addEventListener('click', function() {});
      }

      // 3. Intercept touch and force a click event
      document.addEventListener('touchstart', function(e) {
        // This simulates a mouse click immediately when the finger touches the screen
        if (e.target) {
          e.target.click();
        }
      }, {passive: true});
    })();
  """);
                },
        //         onPageFinished: (_) async {
        //           setState(() => isLoading = false);
        //
        //           // Inject JS fix for iOS click issues
        //           await _controller.runJavaScript("""
        //   document.body.style.webkitTouchCallout='none';
        //   document.body.style.webkitUserSelect='auto';
        //   document.documentElement.style.webkitUserSelect='auto';
        // """);
        //         },
                onWebResourceError: (error) {
                  setState(() => isLoading = false);
                },
              ),
            )
            ..loadRequest(Uri.parse(finalUrl));
        // NavigationDelegate(
        //   onPageStarted: (_) {
        //     setState(() => isLoading = true);
        //   },
        //   onPageFinished: (_) {
        //     setState(() => isLoading = false);
        //   },
        //   onWebResourceError: (error) {
        //     setState(() => isLoading = false);
        //   },
        // ),



    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (savedIp == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        automaticallyImplyLeading: false,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        leading: FlavorConfig.instance.getAppBarLeading(context),
        title: Text(
          "iERP HO View",
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.redAccent,
                // color: Colors.redAccent,
              ),
            ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:waterman_iattandance/constant/api_url/api_url.dart';
// import '../../constant/local_db/local_db.dart';

// class IerpHoWebView extends StatefulWidget {
//   const IerpHoWebView({super.key});

//   @override
//   State<IerpHoWebView> createState() => _IerpHoWebViewState();
// }

// class _IerpHoWebViewState extends State<IerpHoWebView> {
//   String? savedIp;
//   InAppWebViewController? webViewController;

//   bool isLoading = true; // 👈 Loader flag

//   final InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
//     crossPlatform: InAppWebViewOptions(
//       javaScriptEnabled: true,
//       javaScriptCanOpenWindowsAutomatically: true,
//       useShouldOverrideUrlLoading: true,
//       mediaPlaybackRequiresUserGesture: false,
//       supportZoom: true,
//       clearCache: true,
//       cacheEnabled: false,
//     ),
//     android: AndroidInAppWebViewOptions(
//       useHybridComposition: true,
//       domStorageEnabled: true,
//       builtInZoomControls: true,
//       displayZoomControls: true,
//       loadWithOverviewMode: true,
//       useWideViewPort: true,
//     ),
//     ios: IOSInAppWebViewOptions(
//       allowsInlineMediaPlayback: true,
//       allowsBackForwardNavigationGestures: true,
//       sharedCookiesEnabled: true,
//       automaticallyAdjustsScrollIndicatorInsets: true,
//     ),
//   );

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedIp();
//   }

//   Future<void> _loadSavedIp() async {
//     final user = LocalDbController.to.storage.read("IP_Address");
//     setState(() {
//       savedIp = user;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (savedIp == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     final String finalUrl = "http://$savedIp${ApiUrl.iERPHoWebLogin}";

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.red,
//         automaticallyImplyLeading: false,
//         leading: IconButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             icon: Icon(
//               Icons.arrow_back_ios,
//               color: Colors.white,
//             )),
//         title: const Text(
//           "iERP HO View",
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Stack(
//         children: [
//           InAppWebView(
//             initialUrlRequest: URLRequest(
//               url: WebUri(finalUrl),
//             ),
//             initialOptions: options,
//             onWebViewCreated: (controller) {
//               webViewController = controller;
//             },
//             onLoadStart: (controller, url) {
//               print("HO START LOADING: $url");
//               setState(() => isLoading = true); // Show loader
//             },
//             onLoadStop: (controller, url) async {
//               print("HO FINISHED LOADING: $url");
//               setState(() => isLoading = false); // Hide loader
//             },
//             onLoadError: (controller, url, code, message) {
//               print("HO LOAD ERROR ($code): $message --- $url");
//               setState(() => isLoading = false); // Hide loader
//             },
//             onLoadHttpError: (controller, url, statusCode, description) {
//               print("HO HTTP ERROR ($statusCode): $description --- $url");
//               setState(() => isLoading = false); // Hide loader
//             },
//             shouldOverrideUrlLoading: (controller, action) async {
//               final uri = action.request.url!;
//               print("HO URL OVERRIDE: $uri");
//               return NavigationActionPolicy.ALLOW;
//             },
//           ),

//           // Loader Overlay
//           if (isLoading)
//             const Center(
//               child: CircularProgressIndicator(
//                 color: Colors.red,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
