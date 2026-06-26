library breez_sdk_liquid_compat;

import 'dart:convert';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' as spark_sdk;

// ─── WalletInfo ───────────────────────────────────────────────────────────────

class WalletInfo {
  final BigInt balanceSat;
  final BigInt pendingSendSat;
  final BigInt pendingReceiveSat;
  final String fingerprint;
  final String pubkey;
  final List<AssetBalance> assetBalances;

  const WalletInfo({
    required this.balanceSat,
    required this.pendingSendSat,
    required this.pendingReceiveSat,
    required this.fingerprint,
    required this.pubkey,
    required this.assetBalances,
  });

  factory WalletInfo.fromSpark(spark_sdk.GetInfoResponse info) {
    return WalletInfo(
      balanceSat: BigInt.from(info.balanceSats),
      pendingSendSat: BigInt.zero,
      pendingReceiveSat: BigInt.zero,
      fingerprint: info.identityPubkey,
      pubkey: info.identityPubkey,
      assetBalances: const [],
    );
  }
}

class AssetBalance {
  final String asset;
  final BigInt balance;

  const AssetBalance({required this.asset, required this.balance});

  Map<String, dynamic> toJson() => {'asset': asset, 'balance': balance.toString()};

  factory AssetBalance.fromJson(Map<String, dynamic> json) => AssetBalance(
        asset: json['asset'] as String? ?? '',
        balance: BigInt.parse(json['balance'] as String? ?? '0'),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AssetBalance && asset == other.asset && balance == other.balance;

  @override
  int get hashCode => Object.hash(asset, balance);
}

extension AssetBalanceFromJson on AssetBalance {
  static AssetBalance? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return AssetBalance.fromJson(json);
  }
}

extension ListEquality<T> on List<T> {
  bool deepEquals(List<T> other) {
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }
}

// ─── BlockchainInfo ───────────────────────────────────────────────────────────

class BlockchainInfo {
  final int liquidTip;
  final int bitcoinTip;

  const BlockchainInfo({required this.liquidTip, required this.bitcoinTip});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BlockchainInfo && liquidTip == other.liquidTip && bitcoinTip == other.bitcoinTip;

  @override
  int get hashCode => Object.hash(liquidTip, bitcoinTip);
}

// ─── GetInfoResponse ──────────────────────────────────────────────────────────

class GetInfoResponse {
  final WalletInfo walletInfo;
  final BlockchainInfo blockchainInfo;

  const GetInfoResponse({required this.walletInfo, required this.blockchainInfo});

  factory GetInfoResponse.fromSpark(spark_sdk.GetInfoResponse info) {
    return GetInfoResponse(
      walletInfo: WalletInfo.fromSpark(info),
      blockchainInfo: const BlockchainInfo(liquidTip: 0, bitcoinTip: 0),
    );
  }
}

// ─── PaymentState ─────────────────────────────────────────────────────────────

enum PaymentState {
  complete,
  pending,
  failed,
  refundPending,
  refundable,
  waitingForConfirmations,
  receivedPayment,
  waitingFeeAcceptance,
}

// ─── PaymentType ──────────────────────────────────────────────────────────────

enum PaymentType {
  send,
  receive,
}

// ─── PaymentMethod ────────────────────────────────────────────────────────────

enum PaymentMethod {
  lightning,
  liquid,
  bitcoin,
  lnurl;

  String get displayName => name;
}

// ─── PaymentDetails ───────────────────────────────────────────────────────────

class PaymentDetails {
  PaymentDetails._();

  factory PaymentDetails.lightning({
    String? swapId,
    String? description,
    int? liquidExpirationBlockheight,
    String? preimage,
    String? invoice,
    String? bolt12Offer,
    String? paymentHash,
    String? destinationPubkey,
    LnUrlInfo? lnurlInfo,
    String? bip353Address,
    String? payerNote,
    String? claimTxId,
    String? refundTxId,
    BigInt? refundTxAmountSat,
  }) =>
      PaymentDetails_Lightning._(
        swapId: swapId ?? '',
        description: description ?? '',
        liquidExpirationBlockheight: liquidExpirationBlockheight ?? 0,
        preimage: preimage,
        invoice: invoice,
        bolt12Offer: bolt12Offer,
        paymentHash: paymentHash,
        destinationPubkey: destinationPubkey,
        lnurlInfo: lnurlInfo,
        bip353Address: bip353Address,
        payerNote: payerNote,
        claimTxId: claimTxId,
        refundTxId: refundTxId,
        refundTxAmountSat: refundTxAmountSat,
      );

  factory PaymentDetails.liquid({
    String? destination,
    String? description,
    String? assetId,
    AssetInfo? assetInfo,
    LnUrlInfo? lnurlInfo,
    String? bip353Address,
    String? payerNote,
  }) =>
      PaymentDetails_Liquid._(
        destination: destination ?? '',
        description: description ?? '',
        assetId: assetId ?? '',
        assetInfo: assetInfo,
        lnurlInfo: lnurlInfo,
        bip353Address: bip353Address,
        payerNote: payerNote,
      );

  factory PaymentDetails.bitcoin({
    String? swapId,
    String? bitcoinAddress,
    String? description,
    bool? autoAcceptedFees,
    int? liquidExpirationBlockheight,
    int? bitcoinExpirationBlockheight,
    String? claimTxId,
    String? refundTxId,
    BigInt? refundTxAmountSat,
  }) =>
      PaymentDetails_Bitcoin._(
        swapId: swapId ?? '',
        bitcoinAddress: bitcoinAddress ?? '',
        description: description ?? '',
        autoAcceptedFees: autoAcceptedFees ?? false,
        liquidExpirationBlockheight: liquidExpirationBlockheight ?? 0,
        bitcoinExpirationBlockheight: bitcoinExpirationBlockheight ?? 0,
        claimTxId: claimTxId,
        refundTxId: refundTxId,
        refundTxAmountSat: refundTxAmountSat,
      );

  T maybeMap<T>({
    required T Function(PaymentDetails_Lightning) lightning,
    required T Function(PaymentDetails_Liquid) liquid,
    required T Function(PaymentDetails_Bitcoin) bitcoin,
    required T Function() orElse,
  }) {
    if (this is PaymentDetails_Lightning) return lightning(this as PaymentDetails_Lightning);
    if (this is PaymentDetails_Liquid) return liquid(this as PaymentDetails_Liquid);
    if (this is PaymentDetails_Bitcoin) return bitcoin(this as PaymentDetails_Bitcoin);
    return orElse();
  }

  T? maybeWhen<T>({
    T Function()? lightning,
    T Function()? liquid,
    T Function()? bitcoin,
    T Function()? orElse,
  }) {
    if (this is PaymentDetails_Lightning && lightning != null) return lightning();
    if (this is PaymentDetails_Liquid && liquid != null) return liquid();
    if (this is PaymentDetails_Bitcoin && bitcoin != null) return bitcoin();
    return orElse?.call();
  }

  Map<String, dynamic>? toJson() => null;
}

class PaymentDetails_Lightning extends PaymentDetails {
  final String swapId;
  final String description;
  final int liquidExpirationBlockheight;
  final String? preimage;
  final String? invoice;
  final String? bolt12Offer;
  final String? paymentHash;
  final String? destinationPubkey;
  final LnUrlInfo? lnurlInfo;
  final String? bip353Address;
  final String? payerNote;
  final String? claimTxId;
  final String? refundTxId;
  final BigInt? refundTxAmountSat;

  PaymentDetails_Lightning._({
    required this.swapId,
    required this.description,
    required this.liquidExpirationBlockheight,
    this.preimage,
    this.invoice,
    this.bolt12Offer,
    this.paymentHash,
    this.destinationPubkey,
    this.lnurlInfo,
    this.bip353Address,
    this.payerNote,
    this.claimTxId,
    this.refundTxId,
    this.refundTxAmountSat,
  });
}

class PaymentDetails_Liquid extends PaymentDetails {
  final String destination;
  final String description;
  final String assetId;
  final AssetInfo? assetInfo;
  final LnUrlInfo? lnurlInfo;
  final String? bip353Address;
  final String? payerNote;

  PaymentDetails_Liquid._({
    required this.destination,
    required this.description,
    required this.assetId,
    this.assetInfo,
    this.lnurlInfo,
    this.bip353Address,
    this.payerNote,
  });
}

class PaymentDetails_Bitcoin extends PaymentDetails {
  final String swapId;
  final String bitcoinAddress;
  final String description;
  final bool autoAcceptedFees;
  final int liquidExpirationBlockheight;
  final int bitcoinExpirationBlockheight;
  final String? claimTxId;
  final String? refundTxId;
  final BigInt? refundTxAmountSat;

  PaymentDetails_Bitcoin._({
    required this.swapId,
    required this.bitcoinAddress,
    required this.description,
    required this.autoAcceptedFees,
    required this.liquidExpirationBlockheight,
    required this.bitcoinExpirationBlockheight,
    this.claimTxId,
    this.refundTxId,
    this.refundTxAmountSat,
  });
}

// ─── AssetInfo ─────────────────────────────────────────────────────────────────

class AssetInfo {
  final String assetId;
  final String name;
  final String ticker;
  final int precision;

  const AssetInfo({
    required this.assetId,
    required this.name,
    this.ticker = '',
    this.precision = 0,
  });

  Map<String, dynamic> toJson() => {
        'assetId': assetId,
        'name': name,
        'ticker': ticker,
        'precision': precision,
      };

  factory AssetInfo.fromJson(Map<String, dynamic> json) => AssetInfo(
        assetId: json['assetId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        ticker: json['ticker'] as String? ?? '',
        precision: json['precision'] as int? ?? 0,
      );
}

extension AssetInfoFromJson on AssetInfo {
  static AssetInfo? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return AssetInfo.fromJson(json);
  }
}

// ─── LnUrlInfo ─────────────────────────────────────────────────────────────────

class LnUrlInfo {
  final String? lnAddress;
  final String? lnurlPayDomain;
  final String? lnurlPayMetadata;
  final String? comment;
  final String? domain;
  final String? metadata;

  const LnUrlInfo({
    this.lnAddress,
    this.lnurlPayDomain,
    this.lnurlPayMetadata,
    this.comment,
    this.domain,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        if (lnAddress != null) 'lnAddress': lnAddress,
        if (lnurlPayDomain != null) 'lnurlPayDomain': lnurlPayDomain,
        if (lnurlPayMetadata != null) 'lnurlPayMetadata': lnurlPayMetadata,
      };

  String toFormattedString() => 'LnUrlInfo(lnAddress: $lnAddress, domain: $domain)';
}

extension LnUrlInfoFromJson on LnUrlInfo {
  static LnUrlInfo? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return LnUrlInfo(
      lnAddress: json['lnAddress'] as String?,
      lnurlPayDomain: json['lnurlPayDomain'] as String?,
      lnurlPayMetadata: json['lnurlPayMetadata'] as String?,
    );
  }
}

// ─── LNInvoice / LNOffer ──────────────────────────────────────────────────────

class LNInvoice {
  final String bolt11;
  final String paymentHash;
  final BigInt amountMsat;
  final String description;

  const LNInvoice({
    required this.bolt11,
    required this.paymentHash,
    this.amountMsat = BigInt.zero,
    this.description = '',
  });

  String toFormattedString() => 'LNInvoice(invoice: $bolt11, paymentHash: $paymentHash)';
}

class LNOffer {
  final String offer;
  final String description;

  const LNOffer({required this.offer, this.description = ''});

  String toFormattedString() => 'LNOffer(offer: $offer, description: $description)';
}

// ─── LNURL Data Types ─────────────────────────────────────────────────────────

class LnUrlPayRequestData {
  final String callback;
  final int minSendable;
  final int maxSendable;
  final String metadataStr;
  final int commentAllowed;
  final String domain;
  final String url;
  final String? address;
  final bool? allowsNostr;
  final String? nostrPubkey;

  const LnUrlPayRequestData({
    required this.callback,
    required this.minSendable,
    required this.maxSendable,
    required this.metadataStr,
    required this.commentAllowed,
    required this.domain,
    required this.url,
    this.address,
    this.allowsNostr,
    this.nostrPubkey,
  });

  String toFormattedString() =>
      'LnUrlPayRequestData(callback: $callback, minSendable: $minSendable, maxSendable: $maxSendable)';
}

class LnUrlWithdrawRequestData {
  final String callback;
  final String k1;
  final String defaultDescription;
  final int minWithdrawable;
  final int maxWithdrawable;

  const LnUrlWithdrawRequestData({
    required this.callback,
    required this.k1,
    required this.defaultDescription,
    required this.minWithdrawable,
    required this.maxWithdrawable,
  });

  String toFormattedString() =>
      'LnUrlWithdrawRequestData(callback: $callback, minWithdrawable: $minWithdrawable, maxWithdrawable: $maxWithdrawable)';
}

class LnUrlAuthRequestData {
  final String k1;
  final String? action;
  final String domain;
  final String url;

  const LnUrlAuthRequestData({
    required this.k1,
    this.action,
    required this.domain,
    required this.url,
  });

  String toFormattedString() => 'LnUrlAuthRequestData(k1: $k1, action: $action, domain: $domain, url: $url)';
}

class LnUrlErrorData {
  final String reason;

  const LnUrlErrorData({required this.reason});

  String toFormattedString() => 'LnUrlErrorData(reason: $reason)';
}

// ─── InputType (Liquid-style sealed class) ─────────────────────────────────────

class InputType {
  InputType._();
}

class InputType_Bolt11 extends InputType {
  final LNInvoice invoice;
  InputType_Bolt11(this.invoice);
}

class InputType_Bolt12Offer extends InputType {
  final LNOffer offer;
  final String? bip353Address;
  InputType_Bolt12Offer(this.offer, {this.bip353Address});
}

class InputType_LnUrlPay extends InputType {
  final LnUrlPayRequestData data;
  final String? bip353Address;
  InputType_LnUrlPay(this.data, {this.bip353Address});
}

class InputType_LnUrlWithdraw extends InputType {
  final LnUrlWithdrawRequestData data;
  InputType_LnUrlWithdraw(this.data);
}

class InputType_LnUrlAuth extends InputType {
  final LnUrlAuthRequestData data;
  InputType_LnUrlAuth(this.data);
}

class InputType_LnUrlError extends InputType {
  final LnUrlErrorData data;
  InputType_LnUrlError(this.data);
}

class InputType_BitcoinAddress extends InputType {
  final BitcoinAddressData address;
  InputType_BitcoinAddress(this.address);
}

class InputType_LightningAddress extends InputType {
  final String address;
  InputType_LightningAddress(this.address);
}

// ─── BitcoinAddressData ────────────────────────────────────────────────────────

class BitcoinAddressData {
  final String address;
  final spark_sdk.BitcoinNetwork network;

  const BitcoinAddressData({required this.address, required this.network});

  String toFormattedString() => 'BitcoinAddressData(address: $address)';
}

// ─── Payment (Liquid-style) ────────────────────────────────────────────────────

class Payment {
  final String? txId;
  final String? destination;
  final String? unblindingData;
  final BigInt amountSat;
  final BigInt feesSat;
  final PaymentType paymentType;
  final PaymentState status;
  final PaymentDetails details;
  final int timestamp;

  const Payment({
    this.txId,
    this.destination,
    this.unblindingData,
    this.amountSat = BigInt.zero,
    this.feesSat = BigInt.zero,
    required this.paymentType,
    required this.status,
    required this.details,
    this.timestamp = 0,
  });

  factory Payment.fromSpark(spark_sdk.Payment p) {
    return Payment(
      txId: p.id,
      destination: null,
      unblindingData: null,
      amountSat: BigInt.from(p.amount),
      feesSat: BigInt.from(p.fees),
      paymentType: p.paymentType == spark_sdk.PaymentType.send ? PaymentType.send : PaymentType.receive,
      status: _sparkStatusToCompat(p.status),
      details: PaymentDetails.lightning(
        swapId: p.id,
      ),
      timestamp: p.timestamp,
    );
  }

  static PaymentState _sparkStatusToCompat(spark_sdk.PaymentStatus status) {
    switch (status) {
      case spark_sdk.PaymentStatus.completed:
        return PaymentState.complete;
      case spark_sdk.PaymentStatus.pending:
        return PaymentState.pending;
      case spark_sdk.PaymentStatus.failed:
        return PaymentState.failed;
    }
  }
}

// ─── Send/Receive Types ───────────────────────────────────────────────────────

class PrepareSendResponse {
  final String destination;
  final BigInt amount;
  final BigInt feesSat;

  const PrepareSendResponse(this.destination, this.amount, this.feesSat);

  String toFormattedString() => 'PrepareSendResponse(destination: $destination, amount: $amount)';
}

class PrepareSendRequest {
  final String destination;
  final BigInt amount;

  const PrepareSendRequest(this.destination, this.amount);
}

class SendPaymentResponse {
  final Payment payment;

  const SendPaymentResponse(this.payment);
}

class ReceivePaymentResponse {
  final String destination;

  const ReceivePaymentResponse(this.destination);
}

class PrepareReceiveResponse {
  final PaymentMethod? paymentMethod;
  final BigInt amount;
  final BigInt feesSat;

  const PrepareReceiveResponse({this.paymentMethod, this.amount = BigInt.zero, this.feesSat = BigInt.zero});

  BigInt get fee => feesSat;
}

class PrepareReceiveRequest {
  final PaymentMethod paymentMethod;
  final BigInt? amount;

  const PrepareReceiveRequest({required this.paymentMethod, this.amount});
}

class SendPaymentRequest {
  final PrepareSendResponse prepareResponse;
  final String? payerNote;

  const SendPaymentRequest({required this.prepareResponse, this.payerNote});
}

// ─── SuccessAction types ──────────────────────────────────────────────────────

class AesSuccessActionDataDecrypted {
  final String description;
  final String plaintext;
  final String iv;

  const AesSuccessActionDataDecrypted({
    required this.description,
    required this.plaintext,
    required this.iv,
  });
}

extension AesSuccessActionDataDecryptedToJson on AesSuccessActionDataDecrypted {
  Map<String, dynamic> toJson() => {
        'description': description,
        'plaintext': plaintext,
        'iv': iv,
      };
}

extension AesSuccessActionDataDecryptedFromJson on AesSuccessActionDataDecrypted {
  static AesSuccessActionDataDecrypted fromJson(Map<String, dynamic> json) {
    return AesSuccessActionDataDecrypted(
      description: json['description'] as String? ?? '',
      plaintext: json['plaintext'] as String? ?? '',
      iv: json['iv'] as String? ?? '',
    );
  }
}

class MessageSuccessActionData {
  final String message;
  const MessageSuccessActionData({required this.message});
}

class UrlSuccessActionData {
  final String description;
  final String url;
  const UrlSuccessActionData({required this.description, required this.url});
}

class SuccessActionProcessed {
  SuccessActionProcessed._();

  factory SuccessActionProcessed.message(String msg) =>
      SuccessActionProcessed_Message(MessageSuccessActionData(message: msg));
  factory SuccessActionProcessed.url(String url, {String description = ''}) =>
      SuccessActionProcessed_Url(UrlSuccessActionData(description: description, url: url));
  factory SuccessActionProcessed.aes(AesSuccessActionDataDecrypted data) =>
      SuccessActionProcessed_Aes(data);
}

class SuccessActionProcessed_Message extends SuccessActionProcessed {
  final MessageSuccessActionData data;
  SuccessActionProcessed_Message(this.data);
}

class SuccessActionProcessed_Url extends SuccessActionProcessed {
  final UrlSuccessActionData data;
  SuccessActionProcessed_Url(this.data);
}

class SuccessActionProcessed_Aes extends SuccessActionProcessed {
  final AesSuccessActionDataDecrypted data;
  final AesSuccessActionDataResult result;

  SuccessActionProcessed_Aes(this.data)
      : result = AesSuccessActionDataResult_Decrypted(data);
}

class AesSuccessActionDataResult {
  AesSuccessActionDataResult._();
}

class AesSuccessActionDataResult_Decrypted extends AesSuccessActionDataResult {
  final AesSuccessActionDataDecrypted data;
  AesSuccessActionDataResult_Decrypted(this.data);
}

class AesSuccessActionDataResult_ErrorStatus extends AesSuccessActionDataResult {
  final String reason;
  AesSuccessActionDataResult_ErrorStatus(this.reason);
}

extension SuccessActionProcessedToJson on SuccessActionProcessed {
  Map<String, dynamic>? toJson() {
    if (message != null) return {'type': 'message', 'data': message};
    if (url != null) return {'type': 'url', 'data': url};
    if (aesData != null) return {'type': 'aes', 'data': aesData!.toJson()};
    return null;
  }
}

extension SuccessActionProcessedFromJson on SuccessActionProcessed {
  static SuccessActionProcessed? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final String type = json['type'] as String? ?? '';
    switch (type) {
      case 'message':
        return SuccessActionProcessed.message(json['data'] as String? ?? '');
      case 'url':
        return SuccessActionProcessed.url(json['data'] as String? ?? '');
      case 'aes':
        return SuccessActionProcessed.aes(
          AesSuccessActionDataDecryptedFromJson.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
        );
      default:
        return null;
    }
  }
}

// ─── NWC Types (stubs) ────────────────────────────────────────────────────────

class NwcConnectionModel {
  final String? name;
  final String? pubkey;

  const NwcConnectionModel({this.name, this.pubkey});
}

class NwcCubit {
  NwcCubit._();

  factory NwcCubit() => NwcCubit._();
}

class NwcCubitFactory {
  static NwcCubit of(Object context) => NwcCubit._();
}

class NwcPage {
  static const String routeName = '/nwc';
}

class NwcAddConnectionPage {
  static const String routeName = '/nwc/add';
}

class NwcEditConnectionPage {
  static const String routeName = '/nwc/edit';
  final NwcConnectionModel connection;

  const NwcEditConnectionPage({required this.connection});
}

class NwcConnectionDetailPage {
  static const String routeName = '/nwc/detail';
  final NwcConnectionModel connection;

  const NwcConnectionDetailPage({required this.connection});
}

// ─── Refund Types (stubs) ─────────────────────────────────────────────────────

class RefundableSwap {
  final String? id;

  const RefundableSwap({this.id});
}

class RefundState {
  final bool hasRefundables;
  final bool hasNonRefunded;

  const RefundState({this.hasRefundables = false, this.hasNonRefunded = false});
}

class RefundCubit {
  RefundCubit(Object sdk);

  RefundState get state => const RefundState();

  void enableRebroadcast() {}
}

class GetRefundPage {
  static const String routeName = '/get-refund';
}

class RefundPage {
  static const String routeName = '/refund';
  final RefundableSwap swapInfo;

  const RefundPage({required this.swapInfo});
}

// ─── Amountless BTC Types (stubs) ─────────────────────────────────────────────

class AmountlessBtcCubit {
  AmountlessBtcCubit(Object sdk);

  AmountlessBtcState get state => const AmountlessBtcState();

  void fetchPaymentProposedFees(String swapId) {}
  void acceptPaymentProposedFees(String swapId) {}
  void rejectPaymentProposedFees(String swapId) {}
}

class AmountlessBtcState {
  final bool hasError;

  const AmountlessBtcState({this.hasError = false});
}

// ─── Chain Swap Types (stubs) ─────────────────────────────────────────────────

class ChainSwapCubit {
  ChainSwapCubit(Object sdk);

  void rescanOnchainSwaps() {}
}

class SendChainSwapPage {
  static const String routeName = '/send-chain-swap';
}

class PayOnchainRequest {}
class PreparePayOnchainResponse {}
class SendChainSwapFeeOption {}

// ─── Other stubs ──────────────────────────────────────────────────────────────

class BitcoinAddressInputState {
  final BitcoinAddressData data;

  BitcoinAddressInputState(this.data);
}

class Limits {
  final BigInt minSat;
  final BigInt maxSat;

  const Limits({this.minSat = BigInt.zero, this.maxSat = BigInt.zero});
}

class LightningPaymentLimitsResponse {
  final Limits send;
  final Limits receive;

  const LightningPaymentLimitsResponse({this.send = const Limits(), this.receive = const Limits()});
}

class OnchainPaymentLimitsResponse {
  final Limits send;
  final Limits receive;

  const OnchainPaymentLimitsResponse({this.send = const Limits(), this.receive = const Limits()});
}

// ─── LNURL Request/Response types ──────────────────────────────────────────────

class PrepareLnUrlPayRequest {
  final LnUrlPayRequestData req;

  const PrepareLnUrlPayRequest({required this.req});
}

class PrepareLnUrlPayResponse {
  const PrepareLnUrlPayResponse();
}

// ─── LNURL Result types ───────────────────────────────────────────────────────

class LnUrlPayRequest {
  final LnUrlPayRequestData payRequest;
  final int amount;
  final String? comment;

  const LnUrlPayRequest({required this.payRequest, required this.amount, this.comment});
}

class LnUrlPayResult {
  LnUrlPayResult._();

  factory LnUrlPayResult.endpointSuccess(dynamic data) => LnUrlPayResult_EndpointSuccess(data);
  factory LnUrlPayResult.payError(dynamic data) => LnUrlPayResult_PayError(data);
  factory LnUrlPayResult.endpointError(dynamic data) => LnUrlPayResult_EndpointError(data);
}

class LnUrlPayResult_EndpointSuccess extends LnUrlPayResult {
  final dynamic data;
  LnUrlPayResult_EndpointSuccess(this.data);
}

class LnUrlPayResult_PayError extends LnUrlPayResult {
  final dynamic data;
  LnUrlPayResult_PayError(this.data);
}

class LnUrlPayResult_EndpointError extends LnUrlPayResult {
  final dynamic data;
  LnUrlPayResult_EndpointError(this.data);
}

class LnUrlWithdrawRequest {
  final LnUrlWithdrawRequestData withdrawRequest;
  final int amount;

  const LnUrlWithdrawRequest({required this.withdrawRequest, required this.amount});
}

class LnUrlWithdrawResult {
  LnUrlWithdrawResult._();

  factory LnUrlWithdrawResult.ok() => LnUrlWithdrawResult_Ok();
  factory LnUrlWithdrawResult.errorStatus(dynamic data) => LnUrlWithdrawResult_ErrorStatus(data);
}

class LnUrlWithdrawResult_Ok extends LnUrlWithdrawResult {
  LnUrlWithdrawResult_Ok();
}

class LnUrlWithdrawResult_ErrorStatus extends LnUrlWithdrawResult {
  final dynamic data;
  LnUrlWithdrawResult_ErrorStatus(this.data);
}

class LnUrlCallbackStatus {
  LnUrlCallbackStatus._();

  factory LnUrlCallbackStatus.ok() => LnUrlCallbackStatus_Ok();
  factory LnUrlCallbackStatus.errorStatus(dynamic data) => LnUrlCallbackStatus_ErrorStatus(data);
}

class LnUrlCallbackStatus_Ok extends LnUrlCallbackStatus {
  LnUrlCallbackStatus_Ok();
}

class LnUrlCallbackStatus_ErrorStatus extends LnUrlCallbackStatus {
  final dynamic data;
  LnUrlCallbackStatus_ErrorStatus(this.data);
}

// ─── PaymentEvent ──────────────────────────────────────────────────────────────

class PaymentEvent {
  final Payment payment;

  const PaymentEvent(this.payment);
}

// ─── PaymentState extension ───────────────────────────────────────────────────

extension PaymentStateX on PaymentState {
  bool get isComplete => this == PaymentState.complete;
  bool get isPending => this == PaymentState.pending;
  bool get isFailed => this == PaymentState.failed;
}

// ─── BreezDateUtils ───────────────────────────────────────────────────────────

class BreezDateUtils {
  static DateTime? bitcoinBlockDiffToDate({required int blockHeight, required int expiryBlock}) => null;
  static DateTime? liquidBlockDiffToDate({required int blockHeight, required int expiryBlock}) => null;
}

// ─── Rate ──────────────────────────────────────────────────────────────────────

class Rate {
  final String coin;
  final String value;

  const Rate({this.coin = '', this.value = ''});
}

// ─── Utility ──────────────────────────────────────────────────────────────────

T parseEnum<T>({required String value, required List<T> enumValues, required T defaultValue}) {
  try {
    return enumValues.firstWhere((T e) => (e as dynamic).name == value);
  } catch (_) {
    return defaultValue;
  }
}
