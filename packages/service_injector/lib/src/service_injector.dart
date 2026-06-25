import 'dart:async';

import 'package:breez_logger/breez_logger.dart';
import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_sdk_spark/breez_sdk_spark.dart';
import 'package:credentials_manager/credentials_manager.dart';
import 'package:device_client/device_client.dart';
import 'package:keychain/keychain.dart';
import 'package:lightning_links/lightning_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class NotificationsClient {
  Future<String?> getToken();
  Stream<Map<dynamic, dynamic>> get notifications;
}

class NoOpNotificationsClient implements NotificationsClient {
  @override
  Future<String?> getToken() async => null;

  @override
  Stream<Map<dynamic, dynamic>> get notifications => const Stream.empty();
}

class ServiceInjector {
  static final ServiceInjector _singleton = ServiceInjector._internal();
  static ServiceInjector? _injector;

  NotificationsClient? _notifications;

  BreezSDKSpark? _breezSdkSpark;
  LightningLinksService? _lightningLinksService;

  DeviceClient? _deviceClient;
  Future<SharedPreferences>? _sharedPreferences = SharedPreferences.getInstance();
  KeyChain? _keychain;
  CredentialsManager? _credentialsManager;
  BreezPreferences? _breezPreferences;
  BreezLogger? _breezLogger;

  factory ServiceInjector() => _injector ?? _singleton;

  ServiceInjector._internal();

  static void configure(ServiceInjector injector) => _injector = injector;

  NotificationsClient get notifications => _notifications ??= NoOpNotificationsClient();

  DeviceClient get deviceClient => _deviceClient ??= DeviceClient();

  LightningLinksService get lightningLinks => _lightningLinksService ??= LightningLinksService();

  Future<SharedPreferences> get sharedPreferences => _sharedPreferences ??= SharedPreferences.getInstance();

  KeyChain get keychain => _keychain ??= KeyChain();

  CredentialsManager get credentialsManager => _credentialsManager ??= CredentialsManager(keyChain: keychain);

  BreezPreferences get breezPreferences => _breezPreferences ??= const BreezPreferences();

  BreezLogger get breezLogger => _breezLogger ??= BreezLogger();

  BreezSDKSpark get breezSdkSpark => _breezSdkSpark ??= BreezSDKSpark.instance;
}
