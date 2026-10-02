import 'dart:async';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/call_log_model.dart';
import '../../../data/repositories/features/call_log_repository.dart';
import '../../../utils/popups/snackbars.dart';

class CallLogController extends GetxController {
  CallLogController({required this.childUid});

  final String childUid;
  final CallLogRepository _repository = CallLogRepository();

  final RxList<CallLogModel> callLogs = <CallLogModel>[].obs;
  final RxList<CallLogModel> filteredLogs = <CallLogModel>[].obs;
  final Rx<CallLogStats?> stats = Rx<CallLogStats?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final Rx<CallTypeFilter> activeFilter = CallTypeFilter.all.obs;

  StreamSubscription<List<CallLogModel>>? _logsSub;

  @override
  void onInit() {
    super.onInit();
    _initStream();
  }

  @override
  void onClose() {
    _logsSub?.cancel();
    super.onClose();
  }

  void _initStream() {
    _logsSub = _repository.streamCallLogs(childUid, limit: 200).listen(
      (data) {
        callLogs.value = data;
        _applyFilters();
        stats.value = _repository.computeStats(data);
        error.value = '';
        isLoading.value = false;
      },
      onError: (err) {
        error.value = 'Error loading call logs: $err';
        isLoading.value = false;
      },
    );
  }

  void _applyFilters() {
    var result = callLogs.toList();

    switch (activeFilter.value) {
      case CallTypeFilter.all:
        break;
      case CallTypeFilter.incoming:
        result = result.where((l) => l.type == CallType.incoming).toList();
        break;
      case CallTypeFilter.outgoing:
        result = result.where((l) => l.type == CallType.outgoing).toList();
        break;
      case CallTypeFilter.missed:
        result = result.where((l) =>
            l.type == CallType.missed || l.type == CallType.rejected).toList();
        break;
    }

    filteredLogs.value = result;
  }

  void setFilter(CallTypeFilter filter) {
    activeFilter.value = filter;
    _applyFilters();
  }

  Future<void> callNumber(String phoneNumber) async {
    if (phoneNumber == 'Unknown' || phoneNumber.isEmpty) {
      USnackBarHelpers.warningSnackBar(
        title: 'Cannot Call',
        message: 'Phone number not available',
      );
      return;
    }

    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      USnackBarHelpers.errorSnackBar(
        title: 'Error',
        message: 'Could not make call',
      );
    }
  }

  Future<void> smsNumber(String phoneNumber) async {
    if (phoneNumber == 'Unknown' || phoneNumber.isEmpty) {
      USnackBarHelpers.warningSnackBar(
        title: 'Cannot SMS',
        message: 'Phone number not available',
      );
      return;
    }

    final url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      USnackBarHelpers.errorSnackBar(
        title: 'Error',
        message: 'Could not open SMS',
      );
    }
  }

  int get totalCalls => callLogs.length;
  int get missedCount =>
      callLogs.where((l) => l.type == CallType.missed).length;
  int get incomingCount =>
      callLogs.where((l) => l.type == CallType.incoming).length;
  int get outgoingCount =>
      callLogs.where((l) => l.type == CallType.outgoing).length;
  String get totalDuration =>
      stats.value?.totalDurationFormatted ?? '0 min';
  bool get hasLogs => callLogs.isNotEmpty;
}

enum CallTypeFilter {
  all,
  incoming,
  outgoing,
  missed,
}
