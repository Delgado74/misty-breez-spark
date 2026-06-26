import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' as spark_sdk;
import 'package:logging/logging.dart';

final Logger _logger = Logger('AppConfig');

class AppConfig {
  static AppConfig? _instance;

  final spark_sdk.Config sdkConfig;

  AppConfig._(this.sdkConfig);

  static Future<AppConfig> instance() async {
    if (_instance != null) return _instance!;
    _instance = await _load();
    return _instance!;
  }

  static Future<AppConfig> _load() async {
    try {
      final envFile = await rootBundle.loadString('env.json');
      final env = jsonDecode(envFile) as Map<String, dynamic>;

      final apiKey = env['API_KEY'] as String? ?? '';
      final networkStr = env['NETWORK'] as String? ?? 'mainnet';
      final network = networkStr == 'regtest'
          ? spark_sdk.Network.regtest
          : spark_sdk.Network.mainnet;

      final config = spark_sdk.defaultConfig(network: network);
      config.apiKey = apiKey;

      _logger.info('AppConfig loaded: network=$networkStr');
      return AppConfig._(config);
    } catch (e) {
      _logger.severe('Failed to load AppConfig', e);
      rethrow;
    }
  }
}
