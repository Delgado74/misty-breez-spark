import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' as spark_sdk;

class PaymentLimitsState {
  final LightningPaymentLimitsResponse? lightningPaymentLimits;
  final OnchainPaymentLimitsResponse? onchainPaymentLimits;
  final String errorMessage;

  PaymentLimitsState({this.lightningPaymentLimits, this.onchainPaymentLimits, this.errorMessage = ''});

  PaymentLimitsState.initial() : this();

  bool get hasError => errorMessage.isNotEmpty;

  PaymentLimitsState copyWith({
    LightningPaymentLimitsResponse? lightningPaymentLimits,
    OnchainPaymentLimitsResponse? onchainPaymentLimits,
    String? errorMessage,
  }) {
    return PaymentLimitsState(
      lightningPaymentLimits: lightningPaymentLimits ?? this.lightningPaymentLimits,
      onchainPaymentLimits: onchainPaymentLimits ?? this.onchainPaymentLimits,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
