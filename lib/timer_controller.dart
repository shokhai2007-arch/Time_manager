import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

enum TimerStatus { idle, active, paused }

class TimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final TimerStatus status;

  TimerState({
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.status,
  });

  TimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    TimerStatus? status,
  }) {
    return TimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
    );
  }

  double get progress => totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;
}

class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier()
      : super(
          TimerState(
            totalSeconds: 0,
            remainingSeconds: 0,
            status: TimerStatus.idle,
          ),
        );

  Timer? _timer;

  void setDuration(int seconds) {
    state = state.copyWith(
      totalSeconds: seconds,
      remainingSeconds: seconds,
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
    if (state.remainingSeconds <= 0) return;

    state = state.copyWith(status: TimerStatus.active);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);

        if (state.remainingSeconds == 0) {
          unawaited(_vibrate(2000));
          timer.cancel();
          state = state.copyWith(status: TimerStatus.idle);
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
      remainingSeconds: state.totalSeconds,
      status: TimerStatus.idle,
    );
    unawaited(_vibrate(500));
  }

  void hardReset() {
    _timer?.cancel();
    state = TimerState(
      totalSeconds: 0,
      remainingSeconds: 0,
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
