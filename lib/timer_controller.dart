import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        );

  Timer? _timer;

  /// The wall-clock time when the current active run started (or resumed).
  DateTime? _activeStartTime;

  /// The remaining total seconds at the moment the timer was last started/resumed.
  int _totalAtStart = 0;

  /// The remaining period seconds at the moment the timer was last started/resumed.
  int _periodAtStart = 0;

  void setDurations(int total, int period) {
    state = state.copyWith(
      totalSeconds: total,
      remainingTotalSeconds: total,
      periodSeconds: period,
      remainingPeriodSeconds: period,
      status: TimerStatus.idle,
    );
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
  }

  /// Core tick logic — can be called both by the periodic timer AND by
  /// [recalculateAfterResume] so the math is in one place.
  void _tick() {
    if (state.status != TimerStatus.active) return;

    final now = DateTime.now();
    final elapsed = now.difference(_activeStartTime!).inSeconds;

    int newTotal = _totalAtStart - elapsed;
    if (newTotal < 0) newTotal = 0;

    // Derive period from elapsed total seconds.
    final elapsedSinceStart = _totalAtStart - newTotal;
    final periodSecondsElapsed = elapsedSinceStart + (state.periodSeconds - _periodAtStart);
    int newPeriod = state.periodSeconds - (periodSecondsElapsed % state.periodSeconds);

    // Check if a period boundary was just crossed (vibrate).
    if (newPeriod == state.periodSeconds && elapsedSinceStart > 0 && newTotal > 0) {
      unawaited(_vibrate(1000));
    }

    if (newTotal == 0) {
      unawaited(_vibrate(2000));
      _timer?.cancel();
      _activeStartTime = null;
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
  }

  /// Called when the app resumes from background. Recalculates the timer
  /// based on how much wall-clock time has actually passed.
  void recalculateAfterResume() {
    if (state.status != TimerStatus.active || _activeStartTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(_activeStartTime!).inSeconds;

    int newTotal = _totalAtStart - elapsed;
    if (newTotal < 0) newTotal = 0;

    final elapsedSinceStart = _totalAtStart - newTotal;
    final periodSecondsElapsed = elapsedSinceStart + (state.periodSeconds - _periodAtStart);
    int newPeriod = state.periodSeconds - (periodSecondsElapsed % state.periodSeconds);
    if (newPeriod <= 0) newPeriod = state.periodSeconds;

    if (newTotal == 0) {
      _timer?.cancel();
      _activeStartTime = null;
      state = state.copyWith(
        remainingTotalSeconds: 0,
        remainingPeriodSeconds: 0,
        status: TimerStatus.idle,
      );
      unawaited(_vibrate(2000));
    } else {
      state = state.copyWith(
        remainingTotalSeconds: newTotal,
        remainingPeriodSeconds: newPeriod,
      );
    }
  }

  void pause() {
    _timer?.cancel();
    _activeStartTime = null;
    state = state.copyWith(status: TimerStatus.paused);
  }

  void reset() {
    _timer?.cancel();
    _activeStartTime = null;
    state = state.copyWith(
      remainingTotalSeconds: state.totalSeconds,
      remainingPeriodSeconds: state.periodSeconds,
      status: TimerStatus.idle,
    );
    unawaited(_vibrate(500));
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
    unawaited(_vibrate(1000));
  }

  Future<void> _vibrate(int duration) async {
    if (await Vibration.hasVibrator()) {
      unawaited(Vibration.vibrate(duration: duration));
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
