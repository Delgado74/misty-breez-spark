import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' as spark_sdk;
import 'package:logging/logging.dart';

import 'liquid_compat.dart';

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

  final StreamController<GetInfoResponse> _getInfoResponseController =
      StreamController<GetInfoResponse>.broadcast();
  Stream<GetInfoResponse> get getInfoResponseStream => _getInfoResponseController.stream;

  final StreamController<void> _didCompleteInitialSyncController =
      StreamController<void>.broadcast();
  Stream<void> get didCompleteInitialSyncStream => _didCompleteInitialSyncController.stream;

  final StreamController<List<Payment>> _paymentsController = StreamController<List<Payment>>.broadcast();
  Stream<List<Payment>> get paymentsStream => _paymentsController.stream;

  final StreamController<PaymentEvent> _paymentEventController =
      StreamController<PaymentEvent>.broadcast();
  Stream<PaymentEvent> get paymentEventStream => _paymentEventController.stream;

  Future<void> connect({required spark_sdk.ConnectRequest req}) async {
    _sdk = await spark_sdk.connect(request: req);
    _logger.info('Connected to Breez Spark SDK');
    final info = _sdk!.getInfo(request: const spark_sdk.GetInfoRequest());
    _logger.info('Node pubkey: ${info.identityPubkey}');
    _getInfoResponseController.add(GetInfoResponse.fromSpark(info));
  }

  Future<void> disconnect() async {
    _logger.info('Disconnecting from Breez Spark SDK');
    await _sdk?.disconnect();
    _sdk = null;
  }

  // ─── Spark SDK passthrough methods ──────────────────────────────────────────

  Future<PrepareSendResponse> prepareSendPayment({required PrepareSendRequest req}) async {
    _logger.warning('prepareSendPayment stub called');
    return PrepareSendResponse(req.destination, BigInt.zero, BigInt.zero);
  }

  Future<SendPaymentResponse> sendPayment({required PrepareSendResponse prepareResponse, String? payerNote}) async {
    _logger.warning('sendPayment stub called');
    return SendPaymentResponse(
      Payment(
        paymentType: PaymentType.send,
        status: PaymentState.complete,
        details: PaymentDetails.lightning(),
      ),
    );
  }

  Future<PrepareReceiveResponse> prepareReceivePayment({required PrepareReceiveRequest req}) async {
    _logger.warning('prepareReceivePayment stub called');
    return PrepareReceiveResponse(amount: BigInt.zero, feesSat: BigInt.zero);
  }

  Future<ReceivePaymentResponse> receivePayment({required PrepareReceiveResponse prepareResponse}) async {
    _logger.warning('receivePayment stub called');
    return ReceivePaymentResponse('stub_invoice');
  }

  Future<List<Rate>> fetchFiatRates() async {
    _logger.warning('fetchFiatRates stub called');
    return [];
  }

  Future<void> sync() async {
    _logger.info('sync stub called - no-op for Spark SDK');
  }

  // ─── LNURL stub methods ────────────────────────────────────────────────────

  Future<LnUrlWithdrawResult> lnurlWithdraw({required LnUrlWithdrawRequest req}) async {
    _logger.warning('lnurlWithdraw stub called');
    return LnUrlWithdrawResult.ok();
  }

  Future<PrepareLnUrlPayResponse> prepareLnurlPay({required PrepareLnUrlPayRequest req}) async {
    _logger.warning('prepareLnurlPay stub called');
    throw UnimplementedError('LNURL pay not yet implemented in Spark SDK compat');
  }

  Future<LnUrlPayResult> lnurlPay({required LnUrlPayRequest req}) async {
    _logger.warning('lnurlPay stub called');
    throw UnimplementedError('LNURL pay not yet implemented in Spark SDK compat');
  }

  Future<LnUrlCallbackStatus> lnurlAuth({required LnUrlAuthRequestData reqData}) async {
    _logger.warning('lnurlAuth stub called');
    return LnUrlCallbackStatus.ok();
  }
}
