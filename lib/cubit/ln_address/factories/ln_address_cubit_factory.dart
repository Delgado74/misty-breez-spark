import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_sdk_spark/breez_sdk_spark.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/utils/webhooks/message_signer.dart';
import 'package:service_injector/service_injector.dart';

class LnAddressCubitFactory {
  static LnAddressCubit create(ServiceInjector injector, PermissionsCubit permissionsCubit) {
    final BreezSDKSpark breezSdkSpark = injector.breezSdkSpark;
    final BreezPreferences breezPreferences = injector.breezPreferences;
    final WebhookService webhookService = WebhookService(
      breezSdkSpark,
      injector.notifications,
      permissionsCubit,
    );

    final MessageSigner messageSigner = MessageSigner(breezSdkSpark);
    final LnUrlWebhookRequestBuilder requestBuilder = LnUrlWebhookRequestBuilder(messageSigner);
    final UsernameResolver usernameResolver = UsernameResolver(breezPreferences);
    final LnUrlPayService lnAddressService = LnUrlPayService();

    final LnUrlRegistrationManager registrationManager = LnUrlRegistrationManager(
      lnAddressService: lnAddressService,
      breezPreferences: breezPreferences,
      requestBuilder: requestBuilder,
      usernameResolver: usernameResolver,
      webhookService: webhookService,
    );

    return LnAddressCubit(breezSdkSpark: breezSdkSpark, registrationManager: registrationManager);
  }
}
