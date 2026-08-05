import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../flavor_config.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import '../../constant/local_db/local_db.dart';

class IerpKolkataWebView extends StatefulWidget {
  const IerpKolkataWebView({super.key});

  @override
  State<IerpKolkataWebView> createState() => _IerpKolkataWebViewState();
}

class _IerpKolkataWebViewState extends State<IerpKolkataWebView> {
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

    final String finalUrl = "http://$savedIp${ApiUrl.iERPKolkataLogin}";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => isLoading = true);
          },
          onPageFinished: (_) {
            setState(() => isLoading = false);
          },
          onWebResourceError: (error) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));

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
          "iERP Kolkata View",
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child:  CircularProgressIndicator(
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

// class IerpKolkataWebView extends StatefulWidget {
//   const IerpKolkataWebView({super.key});

//   @override
//   State<IerpKolkataWebView> createState() => _IerpKolkataWebViewState();
// }

// class _IerpKolkataWebViewState extends State<IerpKolkataWebView> {
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
//       useWideViewPort: true,
//       loadWithOverviewMode: true,
//       domStorageEnabled: true,
//       builtInZoomControls: true,
//       displayZoomControls: true,
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

//     final String finalUrl = "http://$savedIp${ApiUrl.iERPKolkataLogin}";

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.red,
//         leading: IconButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             icon: Icon(
//               Icons.arrow_back_ios,
//               color: Colors.white,
//             )),
//         title: const Text(
//           "iERP Kolkata View",
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
//               print("KOLKATA LOADING START: $url");
//               setState(() => isLoading = true); // Show loader
//             },
//             onLoadStop: (controller, url) async {
//               print("KOLKATA LOADING FINISHED: $url");
//               setState(() => isLoading = false); // Hide loader
//             },
//             onLoadError: (controller, url, code, message) {
//               print("KOLKATA LOAD ERROR ($code) → $message \nURL → $url");
//               setState(() => isLoading = false); // Hide loader
//             },
//             onLoadHttpError: (controller, url, statusCode, description) {
//               print(
//                   "KOLKATA HTTP ERROR ($statusCode) → $description \nURL → $url");
//               setState(() => isLoading = false); // Hide loader
//             },
//             shouldOverrideUrlLoading: (controller, navAction) async {
//               final uri = navAction.request.url!;
//               print("KOLKATA URL OVERRIDE: $uri");
//               return NavigationActionPolicy.ALLOW;
//             },
//           ),

//           // Loader overlay
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
