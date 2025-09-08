import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/retry.dart' as retry;

import 'package:simplemessenger/config/isrg_x1.dart';
import 'package:simplemessenger/utils/platform_infos.dart';


/// Custom Client to add an additional certificate. This is for the isrg X1
/// certificate which is needed for LetsEncrypt certificates. It is shipped
/// on Android since OS version 7.1. As long as we support older versions we
/// still have to ship this certificate by ourself.
class CustomHttpClient {
  static HttpClient customHttpClient(String? cert) {
    final context = SecurityContext.defaultContext;

    try {
      if (cert != null) {
        final bytes = utf8.encode(cert);
        context.setTrustedCertificatesBytes(bytes);
      }
    } on TlsException catch (e) {
      if (e.osError != null &&
          e.osError!.message.contains('CERT_ALREADY_IN_HASH_TABLE')) {
      } else {
        rethrow;
      }
    }

    final client = HttpClient(context: context);
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 30);
    

    
    return client;
  }

  static http.Client createHTTPClient() {
    return retry.RetryClient(
      PlatformInfos.isAndroid
          ? IOClient(customHttpClient(ISRG_X1))
          : http.Client(),
    );
  }

}
