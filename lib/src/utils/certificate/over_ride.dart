import 'dart:io';

final class CustomHttpOverrides extends HttpOverrides {
  CustomHttpOverrides({required this.bpHost});

  final String bpHost;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final isValidHost = host == bpHost;
        return isValidHost;
      };
  }
}
