import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

const _kTotalSeconds = 'timer_total_seconds';
const _kRemainingTotal = 'timer_remaining_total_seconds';
const _kPeriodSeconds = 'timer_period_seconds';
const _kRemainingPeriod = 'timer_remaining_period_seconds';
const _kStatus = 'timer_status';
const _kActiveStart = 'timer_active_start';
const _kTotalAtStart = 'timer_total_at_start';
const _kPeriodAtStart = 'timer_period_at_start';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStarted,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'timer_service_channel',
      initialNotificationTitle: 'Time Manager',
      initialNotificationContent: 'Timer background service is ready',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onServiceStarted,
      onBackground: onIosBackground,
    ),
  );
}

bool onIosBackground(ServiceInstance service) {
  return true;
}

@pragma('vm:entry-point')
void onServiceStarted(ServiceInstance service) {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Time Manager',
      content: 'Timer is running in the background',
    );
  }

  Timer? backgroundTimer;
  int totalSeconds = 0;
  int remainingTotalSeconds = 0;
  int periodSeconds = 0;
  int remainingPeriodSeconds = 0;
  DateTime? startTime;
  int totalAtStart = 0;
  int periodAtStart = 0;

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTotalSeconds, totalSeconds);
    await prefs.setInt(_kRemainingTotal, remainingTotalSeconds);
    await prefs.setInt(_kPeriodSeconds, periodSeconds);
    await prefs.setInt(_kRemainingPeriod, remainingPeriodSeconds);
    await prefs.setString(_kStatus, 'active');
    await prefs.setInt(_kActiveStart, startTime?.millisecondsSinceEpoch ?? 0);
    await prefs.setInt(_kTotalAtStart, totalAtStart);
    await prefs.setInt(_kPeriodAtStart, periodAtStart);
  }

  void updateNotification() {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Time Manager',
        content: 'Qolgan vaqt: $remainingTotalSeconds soniya',
      );
    }
  }

  Future<void> backgroundTick() async {
    if (startTime == null) return;
    final elapsed = DateTime.now().difference(startTime!).inSeconds;
    int newTotal = totalAtStart - elapsed;
    if (newTotal < 0) newTotal = 0;

    if (periodSeconds > 0) {
      final elapsedSinceStart = totalAtStart - newTotal;
      final periodSecondsElapsed = elapsedSinceStart + (periodSeconds - periodAtStart);
      int newPeriod = periodSeconds - (periodSecondsElapsed % periodSeconds);
      if (newPeriod <= 0) newPeriod = periodSeconds;
      if (newPeriod == periodSeconds && elapsedSinceStart > 0 && newTotal > 0) {
        if (await Vibration.hasVibrator()) {
          await Vibration.vibrate(duration: 1000);
        }
      }
      remainingPeriodSeconds = newPeriod;
    } else {
      remainingPeriodSeconds = 0;
    }

    remainingTotalSeconds = newTotal;

    if (remainingTotalSeconds == 0) {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 2000);
      }
      backgroundTimer?.cancel();
      service.invoke('timerCompleted');
      await saveState();
      await service.stopSelf();
      return;
    }

    await saveState();
    updateNotification();
  }

  service.on('startTimer').listen((event) async {
    totalSeconds = int.tryParse(event?['totalSeconds']?.toString() ?? '0') ?? 0;
    remainingTotalSeconds = int.tryParse(event?['remainingTotalSeconds']?.toString() ?? '$totalSeconds') ?? totalSeconds;
    periodSeconds = int.tryParse(event?['periodSeconds']?.toString() ?? '0') ?? 0;
    remainingPeriodSeconds = int.tryParse(event?['remainingPeriodSeconds']?.toString() ?? '$periodSeconds') ?? periodSeconds;
    startTime = DateTime.now();
    totalAtStart = remainingTotalSeconds;
    periodAtStart = remainingPeriodSeconds;

    backgroundTimer?.cancel();
    backgroundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      backgroundTick();
    });

    await saveState();
    updateNotification();
  });

  service.on('pauseTimer').listen((event) async {
    backgroundTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStatus, 'paused');
  });

  service.on('stopService').listen((event) async {
    backgroundTimer?.cancel();
    await saveState();
    await service.stopSelf();
  });
}
