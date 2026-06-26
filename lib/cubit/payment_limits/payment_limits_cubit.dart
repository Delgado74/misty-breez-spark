import 'dart:async';

import 'package:breez_sdk_spark/breez_sdk_spark.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/utils/utils.dart';

export 'payment_limits_state.dart';

final Logger _logger = Logger('PaymentLimitsCubit');

class PaymentLimitsCubit extends Cubit<PaymentLimitsState> {
  final BreezSDKSpark _breezSdkSpark;

  PaymentLimitsCubit(this._breezSdkSpark) : super(PaymentLimitsState.initial()) {
    _fetchPaymentLimits();
    _refreshPaymentLimitsOnResume();
  }

  StreamSubscription<FGBGType>? fgBgEventsStreamSubscription;

  void _refreshPaymentLimitsOnResume() {
    fgBgEventsStreamSubscription = FGBGEvents.instance.stream.listen((FGBGType event) {
      if (event == FGBGType.foreground) {
        _fetchPaymentLimits();
      }
    });
  }

  void _fetchPaymentLimits() {
    emit(state.copyWith(errorMessage: ''));
  }

  @override
  Future<void> close() {
    fgBgEventsStreamSubscription?.cancel();
    return super.close();
  }

  Future<LightningPaymentLimitsResponse?> fetchLightningLimits() async {
    emit(state.copyWith(errorMessage: ''));
    return LightningPaymentLimitsResponse();
  }

  Future<OnchainPaymentLimitsResponse?> fetchOnchainLimits() async {
    emit(state.copyWith(errorMessage: ''));
    return OnchainPaymentLimitsResponse();
  }

  @override
  void emit(PaymentLimitsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }
}
