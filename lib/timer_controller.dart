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

    state = state.copyWith(status: TimerStatus.active);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTotalSeconds > 0) {
        final int newTotal = state.remainingTotalSeconds - 1;
        int newPeriod = state.remainingPeriodSeconds - 1;

        if (newPeriod <= 0 && newTotal > 0) {
          unawaited(_vibrate(3000));
          newPeriod = state.periodSeconds;
        }

        if (newTotal == 0) {
          unawaited(_vibrate(2000));
          timer.cancel();
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
      } else {
        timer.cancel();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      remainingTotalSeconds: state.totalSeconds,
      remainingPeriodSeconds: state.periodSeconds,
      status: TimerStatus.idle,
    );
    unawaited(_vibrate(500));
  }

  void hardReset() {
    _timer?.cancel();
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
