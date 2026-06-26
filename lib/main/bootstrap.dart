import 'dart:async';

import 'package:breez_logger/breez_logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' as spark_sdk;
import 'package:flutter_svg/svg.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/main/main.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:service_injector/service_injector.dart';

final Logger _logger = Logger('Bootstrap');

typedef AppBuilder =
    Widget Function(ServiceInjector serviceInjector, SdkConnectivityCubit sdkConnectivityCubit);

Future<void> bootstrap(AppBuilder builder) async {
  // runZonedGuarded wrapper is required to log Dart errors.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _precacheSvgImages();
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      // Initialize library
      await _initializeBreezSdkSpark();
      final ServiceInjector injector = ServiceInjector();
      final BreezLogger breezLogger = injector.breezLogger;
      breezLogger.registerBreezSdkSparkLogs(injector.breezSdkSpark);
      BreezDateUtils.setupLocales();

      await HydratedBlocStorage().initialize();

      final SdkConnectivityCubit sdkConnectivityCubit = SdkConnectivityCubit(
        breezSdkSpark: injector.breezSdkSpark,
        credentialsManager: injector.credentialsManager,
      );
      final bool isOnboardingComplete = await OnboardingPreferences.isOnboardingComplete();
      if (isOnboardingComplete) {
        _logger.info('Reconnect if secure storage has mnemonic.');
        final String? mnemonic = await injector.credentialsManager.restoreMnemonic();
        if (mnemonic != null) {
          await sdkConnectivityCubit.reconnect(mnemonic: mnemonic);
        }
      }
      runApp(builder(injector, sdkConnectivityCubit));
    },
    (Object error, StackTrace stackTrace) async {
      if (error is! FlutterErrorDetails) {
        _logger.severe('FlutterError: $error', error, stackTrace);
      }
    },
  );
}

Future<void> _initializeBreezSdkSpark() async {
  try {
    await spark_sdk.BreezSdkSparkLib.init();
    spark_sdk.initLogging();
  } catch (error, stackTrace) {
    _logger.severe('Failed to initialize Breez SDK - Spark: $error', error, stackTrace);
    runApp(BootstrapErrorPage(error: error, stackTrace: stackTrace));
  }
}

Future<void> _precacheSvgImages() async {
  final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final List<String> assets = assetManifest.listAssets();

  final Iterable<String> svgPaths = assets.where((String path) => path.endsWith('.svg'));
  for (final String svgPath in svgPaths) {
    final SvgAssetLoader loader = SvgAssetLoader(svgPath);
    await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }
}
