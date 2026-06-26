import 'dart:async';

import 'package:breez_sdk_spark/breez_sdk_spark.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:rxdart/rxdart.dart';

export 'models/models.dart';
export 'payments_state.dart';

final Logger _logger = Logger('PaymentsCubit');

class PaymentsCubit extends Cubit<PaymentsState> with HydratedMixin<PaymentsState> {
  static const String paymentFilterSettingsKey = 'payment_filter_settings';

  final StreamController<PaymentFilters> _paymentFiltersStreamController = BehaviorSubject<PaymentFilters>();

  Stream<PaymentFilters> get paymentFiltersStream => _paymentFiltersStreamController.stream;

  final BreezSDKSpark _breezSdkSpark;

  PaymentsCubit(this._breezSdkSpark) : super(PaymentsState.initial()) {
    hydrate();

    _paymentFiltersStreamController.add(state.paymentFilters);

    _listenPaymentChanges();
  }

  void _listenPaymentChanges() {
    _logger.info('_listenPaymentChanges\nListening to changes in payments');
    final BreezTranslations texts = getSystemAppLocalizations();

    Rx.combineLatest2<List<Payment>, PaymentFilters, PaymentsState>(
      _breezSdkSpark.paymentsStream,
      paymentFiltersStream,
      (List<Payment> payments, PaymentFilters paymentFilters) {
        return state.copyWith(
          payments: payments.map((Payment e) => PaymentData.fromPayment(e, texts)).toList(),
          paymentFilters: paymentFilters,
        );
      },
    ).distinct().listen((PaymentsState newState) => emit(newState));
  }

  StreamSubscription<Payment> trackPaymentEvents({
    required bool Function(Payment) paymentFilter,
    required void Function(Payment) onData,
    Function? onError,
  }) {
    return _breezSdkSpark.paymentEventStream
        .map((PaymentEvent e) => e.payment)
        .where(paymentFilter)
        .listen((Payment payment) => onData.call(payment), onError: onError);
  }

  Future<StreamSubscription<Payment>> trackIncomingPayments({
    required PaymentTrackingConfig trackingConfig,
    required void Function(Payment) onData,
    void Function(Object)? onError,
  }) async {
    final Set<String> excludedIds = await _getExistingPaymentIds();

    final PaymentTrackingFilter paymentFilter = PaymentTrackingFilter(
      trackingConfig: trackingConfig,
      excludedIds: excludedIds,
    );

    return _breezSdkSpark.paymentsStream
        .expand((List<Payment> payments) => payments)
        .where(paymentFilter.passes)
        .listen(onData, onError: onError);
  }

  Future<Set<String>> _getExistingPaymentIds() async {
    final List<Payment> payments = await _breezSdkSpark.paymentsStream.take(1).first;
    return payments.map((Payment p) => p.trackingId).where((String id) => id.isNotEmpty).toSet();
  }

  Future<PrepareSendResponse> prepareSendPayment({required PrepareSendRequest req}) async {
    _logger.info('prepareSendPayment\nPreparing send payment');
    try {
      return await _breezSdkSpark.prepareSendPayment(req: req);
    } catch (e) {
      _logger.severe('prepareSendPayment\nError preparing send payment', e);
      return Future<PrepareSendResponse>.error(e);
    }
  }

  Future<SendPaymentResponse> sendPayment({
    required PrepareSendResponse prepareResponse,
    String? payerNote,
  }) async {
    _logger.info('sendPayment\nSending payment');
    try {
      return await _breezSdkSpark.sendPayment(prepareResponse: prepareResponse, payerNote: payerNote);
    } catch (e) {
      _logger.severe('sendPayment\nError sending payment', e);
      return Future<SendPaymentResponse>.error(e);
    }
  }

  Future<PrepareReceiveResponse> prepareReceivePayment({
    required PaymentMethod paymentMethod,
    BigInt? payerAmountSat,
  }) async {
    _logger.info('prepareReceivePayment\nPreparing receive payment for $payerAmountSat sats');
    try {
      final PrepareReceiveRequest req = PrepareReceiveRequest(
        paymentMethod: paymentMethod,
        amount: payerAmountSat,
      );
      return await _breezSdkSpark.prepareReceivePayment(req: req);
    } catch (e) {
      _logger.severe('prepareSendPayment\nError preparing receive payment', e);
      return Future<PrepareReceiveResponse>.error(e);
    }
  }

  Future<ReceivePaymentResponse> receivePayment({
    required PrepareReceiveResponse prepareResponse,
    String? description,
  }) async {
    _logger.info('receivePayment\nReceive payment for amount: $prepareResponse');
    try {
      return await _breezSdkSpark.receivePayment(prepareResponse: prepareResponse);
    } catch (e) {
      _logger.severe('receivePayment\nError receiving payment', e);
      return Future<ReceivePaymentResponse>.error(e);
    }
  }

  void changePaymentFilter({List<PaymentType>? filters, int? fromTimestamp, int? toTimestamp}) async {
    final PaymentFilters newPaymentFilters = state.paymentFilters.copyWith(
      filters: filters,
      fromTimestamp: fromTimestamp,
      toTimestamp: toTimestamp,
    );
    _logger.info('changePaymentFilter\nChanging payment filter: $newPaymentFilters');
    _paymentFiltersStreamController.add(newPaymentFilters);
  }

  @override
  PaymentsState? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _logger.severe('No stored data found.');
      return null;
    }

    try {
      final PaymentsState result = PaymentsState.fromJson(json);
      _logger.fine('Successfully hydrated with $result');
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error hydrating: $e');
      _logger.fine('Stack trace: $stackTrace');
      return PaymentsState.initial();
    }
  }

  @override
  Map<String, dynamic>? toJson(PaymentsState state) {
    try {
      final Map<String, dynamic> result = state.toJson();
      _logger.fine('Serialized: $result');
      return result;
    } catch (e) {
      _logger.severe('Error serializing: $e');
      return null;
    }
  }

  @override
  String get storagePrefix => defaultTargetPlatform == TargetPlatform.iOS ? 'IWa' : 'PaymentsCubit';
}
