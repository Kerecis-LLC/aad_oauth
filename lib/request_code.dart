import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'request/authorization_request.dart';
import 'model/config.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as WindowWebview;

class RequestCode {
  final Config _config;
  final AuthorizationRequest _authorizationRequest;

  String? _code;

  RequestCode(Config config)
      : _config = config,
        _authorizationRequest = AuthorizationRequest(config);
  Future<String?> requestCode() async {
    _code = null;
    final urlParams = _constructUrlParams();
    var webView;
    if (!kIsWeb && Platform.isWindows) {
      final _controller = WindowWebview.WebviewController();
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller
          .setPopupWindowPolicy(WindowWebview.WebviewPopupWindowPolicy.allow);
      await _controller.loadUrl('${_authorizationRequest.url}?$urlParams');
      webView = WindowWebview.Webview(_controller);
    } else {
      webView = WebView(
          initialUrl: '${_authorizationRequest.url}?$urlParams',
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: _navigationDelegate,
          backgroundColor: Colors.transparent);
    }

    await _config.navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
            body: SafeArea(
          child: Stack(
            children: [_config.loader, webView],
          ),
        )),
      ),
    );
    return _code;
  }

  FutureOr<NavigationDecision> _navigationDelegate(NavigationRequest request) {
    var uri = Uri.parse(request.url);

    if (uri.queryParameters['error'] != null) {
      _config.navigatorKey.currentState!.pop();
    }

    if (uri.queryParameters['code'] != null) {
      _code = uri.queryParameters['code'];
      _config.navigatorKey.currentState!.pop();
    }
    return NavigationDecision.navigate;
  }

  Future<void> clearCookies() async {
    await CookieManager().clearCookies();
  }

  String _constructUrlParams() =>
      _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params.forEach((String key, String value) =>
        queryParams.add('$key=${Uri.encodeQueryComponent(value)}'));
    return queryParams.join('&');
  }
}
