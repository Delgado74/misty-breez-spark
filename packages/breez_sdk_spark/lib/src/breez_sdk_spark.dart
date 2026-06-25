import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' as spark_sdk;
import 'package:logging/logging.dart';

final Logger _logger = Logger('BreezSDKSpark');

class BreezSDKSpark {
  BreezSDKSpark._();

  static final BreezSDKSpark _instance = BreezSDKSpark._();
  static BreezSDKSpark get instance => _instance;

  spark_sdk.BreezSdk? _sdk;
  spark_sdk.BreezSdk? get sdk => _sdk;

  final StreamController<spark_sdk.LogEntry> _logController =
      StreamController<spark_sdk.LogEntry>.broadcast();
  Stream<spark_sdk.LogEntry> get logStream => _logController.stream;

  Future<void> connect({required spark_sdk.ConnectRequest req}) async {
    _sdk = await spark_sdk.connect(request: req);
    _logger.info('Connected to Breez Spark SDK');
    _logger.info('Node pubkey: ${_sdk!.get_info(request: const spark_sdk.GetInfoRequest()).identity_pubkey}');
  }

  Future<void> disconnect() async {
    _logger.info('Disconnecting from Breez Spark SDK');
    await _sdk?.disconnect();
    _sdk = null;
  }
}
