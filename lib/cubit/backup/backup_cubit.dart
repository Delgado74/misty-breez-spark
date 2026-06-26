import 'package:breez_sdk_spark/breez_sdk_spark.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'backup_state.dart';

final Logger _logger = Logger('BackupCubit');

class BackupCubit extends Cubit<BackupState?> {
  final BreezSDKSpark _breezSdkSpark;

  BackupCubit(this._breezSdkSpark) : super(null);

  // TODO(erdemyerebasmaz): Liquid - Listen to Backup events
  // ignore: unused_element
  void _listenBackupEvents() {
    // _breezSdkSpark.backupStream.listen((event) {
    //   _logger.info('got state: $event');
    // });
  }

  /// Start the backup process
  Future<void> backup() async {
    try {
      emit(BackupState(status: BackupStatus.inProgress));
      _breezSdkSpark.sdk?.backup(req: const BackupRequest());
      emit(BackupState(status: BackupStatus.success));
    } catch (e) {
      _logger.info('Failed to backup');
      emit(BackupState(status: BackupStatus.failed));
    }
  }
}
