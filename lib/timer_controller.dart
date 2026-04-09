import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

enum TimerStatus { idle, active, paused }

class TimerState {
  final int totalSeconds;
  final int remainingTotalSeconds;
  final int periodSeconds;
  final int remainingPeriodSeconds;
  final TimerStatus status;

  TimerState({
    required this.totalSeconds,
    required this.remainingTotalSeconds,
    required this.periodSeconds,
    required this.remainingPeriodSeconds,
    required this.status,
  });

  TimerState copyWith({
    int? totalSeconds,
    int? remainingTotalSeconds,
    int? periodSeconds,
    int? remainingPeriodSeconds,
    TimerStatus? status,
  }) {
    return TimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingTotalSeconds:
          remainingTotalSeconds ?? this.remainingTotalSeconds,
      periodSeconds: periodSeconds ?? this.periodSeconds,
      remainingPeriodSeconds:
          remainingPeriodSeconds ?? this.remainingPeriodSeconds,
      status: status ?? this.status,
    );
  }

  double get periodProgress =>
      periodSeconds > 0 ? remainingPeriodSeconds / periodSeconds : 0;
  double get totalProgress =>
      totalSeconds > 0 ? remainingTotalSeconds / totalSeconds : 0;
}

class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier()
      : super(
          TimerState(
            totalSeconds: 0,
            remainingTotalSeconds: 0,
            periodSeconds: 0,
            remainingPeriodSeconds: 0,
            status: TimerStatus.idle,
          ),
        ) {
    _restoreState();
  }

  static const _kTotalSeconds = 'timer_total_seconds';
  static const _kRemainingTotal = 'timer_remaining_total_seconds';
  static const _kPeriodSeconds = 'timer_period_seconds';
  static const _kRemainingPeriod = 'timer_remaining_period_seconds';
  static const _kStatus = 'timer_status';
  static const _kActiveStart = 'timer_active_start';
  static const _kTotalAtStart = 'timer_total_at_start';
  static const _kPeriodAtStart = 'timer_period_at_start';

  Timer? _timer;

  /// The wall-clock time when the current active run started (or resumed).
  DateTime? _activeStartTime;

  /// The remaining total seconds at the moment the timer was last started/resumed.
  int _totalAtStart = 0;

  /// The remaining period seconds at the moment the timer was last started/resumed.
  int _periodAtStart = 0;

  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();

  Future<void> _ensureBackgroundService() async {
    if (!await _backgroundService.isRunning()) {
      await _backgroundService.startService();
    }
  }

  Future<void> _sendTimerToBackgroundService() async {
    try {
      await _ensureBackgroundService();
      _backgroundService.invoke('startTimer', {
        'totalSeconds': state.totalSeconds,
        'remainingTotalSeconds': state.remainingTotalSeconds,
        'periodSeconds': state.periodSeconds,
        'remainingPeriodSeconds': state.remainingPeriodSeconds,
      });
    } catch (_) {
      // Ignore background service invocation errors.
    }
  }

  Future<void> _stopBackgroundService() async {
    try {
      if (await _backgroundService.isRunning()) {
        _backgroundService.invoke('stopService');
      }
    } catch (_) {
      // Ignore errors when stopping the service.
    }
  }

  void setDurations(int total, int period) {
    final sanitizedTotal = total > 0 ? total : 60;
    final sanitizedPeriod = period > 0 ? period : 10;
    state = state.copyWith(
      totalSeconds: sanitizedTotal,
      remainingTotalSeconds: sanitizedTotal,
      periodSeconds: sanitizedPeriod,
      remainingPeriodSeconds: sanitizedPeriod,
      status: TimerStatus.idle,
    );
    _activeStartTime = null;
    _totalAtStart = 0;
    _periodAtStart = 0;
    _saveState();
  }

  void toggle() {
    if (state.status == TimerStatus.active) {
      pause();
    } else {
      start();
    }
  }

  void start() {
    if (state.remainingTotalSeconds <= 0) return;

    // Record the wall-clock anchor and snapshot of remaining values.
    _activeStartTime = DateTime.now();
    _totalAtStart = state.remainingTotalSeconds;
    _periodAtStart = state.remainingPeriodSeconds;

    state = state.copyWith(status: TimerStatus.active);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
    _sendTimerToBackgroundService();
  }

  /// Core tick logic — can be called both by the periodic timer AND by
  /// [recalculateAfterResume] so the math is in one place.
  void _tick() {
    if (state.status != TimerStatus.active) return;

    final now = DateTime.now();
    final elapsed = now.difference(_activeStartTime!).inSeconds;

    int newTotal = _totalAtStart - elapsed;
    if (newTotal < 0) newTotal = 0;

    if (state.periodSeconds <= 0) {
      state = state.copyWith(
        remainingTotalSeconds: newTotal,
        remainingPeriodSeconds: 0,
      );
      _saveState();
      return;
    }

    // Derive period from elapsed total seconds.
    final elapsedSinceStart = _totalAtStart - newTotal;
    final periodSecondsElapsed =
        elapsedSinceStart + (state.periodSeconds - _periodAtStart);
    int newPeriod =
        state.periodSeconds - (periodSecondsElapsed % state.periodSeconds);

    if (newTotal == 0) {
      _timer?.cancel();
      _activeStartTime = null;
      _stopBackgroundService();
      state = state.copyWith(
        remainingTotalSeconds: 0,
        remainingPeriodSeconds: 0,
        status: TimerStatus.idle,
      );
    } else {
      if (newPeriod <= 0) newPeriod = state.periodSeconds;
      state = state.copyWith(
        remainingTotalSeconds: newTotal,
        remainingPeriodSeconds: newPeriod,
      );
    }
    _saveState();
  }

  /// Called when the app resumes from background. Recalculates the timer
  /// based on how much wall-clock time has actually passed.
  void recalculateAfterResume() {
    if (state.status != TimerStatus.active || _activeStartTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(_activeStartTime!).inSeconds;

    int newTotal = _totalAtStart - elapsed;
    if (newTotal < 0) newTotal = 0;

    if (state.periodSeconds <= 0) {
      state = state.copyWith(
        remainingTotalSeconds: newTotal,
        remainingPeriodSeconds: 0,
      );
      _saveState();
      return;
    }

    final elapsedSinceStart = _totalAtStart - newTotal;
    final periodSecondsElapsed =
        elapsedSinceStart + (state.periodSeconds - _periodAtStart);
    int newPeriod =
        state.periodSeconds - (periodSecondsElapsed % state.periodSeconds);
    if (newPeriod <= 0) newPeriod = state.periodSeconds;

    if (newTotal == 0) {
      _timer?.cancel();
      _activeStartTime = null;
      _stopBackgroundService();
      state = state.copyWith(
        remainingTotalSeconds: 0,
        remainingPeriodSeconds: 0,
        status: TimerStatus.idle,
      );
    } else {
      state = state.copyWith(
        remainingTotalSeconds: newTotal,
        remainingPeriodSeconds: newPeriod,
      );
    }
    _saveState();
  }

  void pause() {
    _timer?.cancel();
    _activeStartTime = null;
    state = state.copyWith(status: TimerStatus.paused);
    _stopBackgroundService();
    _saveState();
  }

  void reset() {
    _timer?.cancel();
    _activeStartTime = null;
    state = state.copyWith(
      remainingTotalSeconds: state.totalSeconds,
      remainingPeriodSeconds: state.periodSeconds,
      status: TimerStatus.idle,
    );
    _stopBackgroundService();
    _vibrate(500);
    _saveState();
  }

  void hardReset() {
    _timer?.cancel();
    _activeStartTime = null;
    state = TimerState(
      totalSeconds: 0,
      remainingTotalSeconds: 0,
      periodSeconds: 0,
      remainingPeriodSeconds: 0,
      status: TimerStatus.idle,
    );
    _stopBackgroundService();
    _vibrate(1000);
    _saveState();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTotalSeconds, state.totalSeconds);
    await prefs.setInt(_kRemainingTotal, state.remainingTotalSeconds);
    await prefs.setInt(_kPeriodSeconds, state.periodSeconds);
    await prefs.setInt(_kRemainingPeriod, state.remainingPeriodSeconds);
    await prefs.setString(_kStatus, state.status.name);

    if (_activeStartTime != null) {
      await prefs.setInt(
          _kActiveStart, _activeStartTime!.millisecondsSinceEpoch);
      await prefs.setInt(_kTotalAtStart, _totalAtStart);
      await prefs.setInt(_kPeriodAtStart, _periodAtStart);
    } else {
      await prefs.remove(_kActiveStart);
      await prefs.remove(_kTotalAtStart);
      await prefs.remove(_kPeriodAtStart);
    }
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final statusString = prefs.getString(_kStatus);
    if (statusString == null) return;

    final total = prefs.getInt(_kTotalSeconds) ?? 0;
    final remainingTotal = prefs.getInt(_kRemainingTotal) ?? 0;
    final period = prefs.getInt(_kPeriodSeconds) ?? 0;
    final remainingPeriod = prefs.getInt(_kRemainingPeriod) ?? 0;
    final activeStartMillis = prefs.getInt(_kActiveStart);
    final totalAtStart = prefs.getInt(_kTotalAtStart) ?? remainingTotal;
    final periodAtStart = prefs.getInt(_kPeriodAtStart) ?? remainingPeriod;

    final restoredStatus = TimerStatus.values.firstWhere(
      (value) => value.name == statusString,
      orElse: () => TimerStatus.idle,
    );

    if (restoredStatus == TimerStatus.active && activeStartMillis != null) {
      final startTime = DateTime.fromMillisecondsSinceEpoch(activeStartMillis);
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final newTotal = totalAtStart - elapsed;
      if (newTotal <= 0) {
        state = state.copyWith(
          totalSeconds: total,
          remainingTotalSeconds: 0,
          periodSeconds: period,
          remainingPeriodSeconds: 0,
          status: TimerStatus.idle,
        );
        _activeStartTime = null;
      } else {
        final elapsedSinceStart = totalAtStart - newTotal;
        final periodSecondsElapsed =
            elapsedSinceStart + (period - periodAtStart);
        int newPeriod = period - (periodSecondsElapsed % period);
        if (newPeriod <= 0) newPeriod = period;

        state = TimerState(
          totalSeconds: total,
          remainingTotalSeconds: newTotal,
          periodSeconds: period,
          remainingPeriodSeconds: newPeriod,
          status: TimerStatus.active,
        );
        _activeStartTime = startTime;
        _totalAtStart = totalAtStart;
        _periodAtStart = periodAtStart;
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          _tick();
        });
      }
    } else {
      state = TimerState(
        totalSeconds: total,
        remainingTotalSeconds: remainingTotal,
        periodSeconds: period,
        remainingPeriodSeconds: remainingPeriod,
        status: restoredStatus,
      );
      if (restoredStatus == TimerStatus.paused) {
        _activeStartTime = null;
        _totalAtStart = totalAtStart;
        _periodAtStart = periodAtStart;
      }
    }
  }

  Future<void> _vibrate(int duration) async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: duration);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});
