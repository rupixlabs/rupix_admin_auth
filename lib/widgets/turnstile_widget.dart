import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TurnstileWidget extends StatefulWidget {
  final String siteKey;
  final String? baseUrl;
  final Function(String token) onVerified;
  final Function() onExpired;
  final Function(String error)? onError;

  const TurnstileWidget({
    super.key,
    required this.siteKey,
    this.baseUrl,
    required this.onVerified,
    required this.onExpired,
    this.onError,
  });

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // On web, webview_flutter is not supported — auto-verify immediately
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVerified('web-bypass');
      });
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'TurnstileChannel',
        onMessageReceived: (message) {
          final msg = message.message;
          if (msg.startsWith('TOKEN:')) {
            widget.onVerified(msg.substring(6));
          } else if (msg == 'EXPIRED') {
            widget.onExpired();
          } else if (msg == 'ERROR') {
            widget.onError?.call('Verification Error');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    _loadContent();
  }

  void _loadContent() {
    // IMPORTANT: Setting the correct baseUrl is CRITICAL fix for "Invalid Domain" error
    final baseUrl = widget.baseUrl ?? 'https://ashapura.api.rupix.io';

    final html =
        '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit" async defer></script>
    <style>
        body { 
            margin: 0; 
            padding: 0; 
            display: flex; 
            justify-content: center; 
            background: transparent; 
            overflow: hidden;
        }
        #widget-container { width: 100%; display: flex; justify-content: center; }
    </style>
</head>
<body>
    <div id="widget-container"></div>
    <script>
        window.onload = function() {
            setTimeout(function() {
                if (typeof turnstile !== 'undefined') {
                    turnstile.render('#widget-container', {
                        sitekey: '${widget.siteKey}',
                        callback: function(token) {
                            TurnstileChannel.postMessage('TOKEN:' + token);
                        },
                        'expired-callback': function() {
                            TurnstileChannel.postMessage('EXPIRED');
                        },
                        'error-callback': function() {
                            TurnstileChannel.postMessage('ERROR');
                        },
                        theme: 'dark',
                        size: 'normal'
                    });
                } else {
                    TurnstileChannel.postMessage('ERROR');
                }
            }, 500); // Small delay for widget stability
        };
    </script>
</body>
</html>
''';
    _controller.loadHtmlString(html, baseUrl: baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    // On web, Turnstile is auto-verified — render nothing
    if (kIsWeb) return const SizedBox.shrink();

    return SizedBox(
      height: 75, // Standard Turnstile height
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}
