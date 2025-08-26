import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// The code you provided is written in Dart and defines a class
///  called `CheckNetwork`. Here's a
/// breakdown of what each part of the code does:

@immutable
final class CheckNetwork {
  /// The code `CheckNetwork({required Connectivity connectivity}) :
  ///  _connectivity = connectivity;` is a
  /// constructor for the `CheckNetwork` class. It takes a required parameter
  ///  `connectivity` of type
  /// `Connectivity` and assigns it to the private field `_connectivity`.

  // const CheckNetwork({required Connectivity connectivity})
  //     : _connectivity = connectivity;
  CheckNetwork() {
    _connectivity = Connectivity();
  }

  /// Check if the device is connected to the internet (Wi-Fi or mobile data).
  ///
  /// Returns `true` if the device is connected to the internet.
  /// Returns `false` if the device is not connected to the internet.
  late final Connectivity _connectivity;

  /// The `isConnected` method is an asynchronous method that checks
  /// if the device is connected to the
  /// internet. Here's a breakdown of what each part of the method does:
  Future<bool> get isConnected async {
    final connectivityResults = await _connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.mobile) ||
        connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.ethernet)) {
      return true;
    } else {
      return false;
    }
  }
}
