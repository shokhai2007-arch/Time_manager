import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timer_controller.dart';
import 'decorators.dart';
import 'widgets/haptic_ring.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const NeumorphicApp(
      debugShowCheckedModeBanner: false,
      title: 'Pitch Timer',
      themeMode: ThemeMode.light,
      theme: NeumorphicThemeData(
        baseColor: NeumorphicDecorator.baseColor,
        lightSource: LightSource.topLeft,
        depth: 10,
        intensity: 0.5,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final TextEditingController _inputController = TextEditingController(text: '60');

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

    final isIdle = timerState.status == TimerStatus.idle;

    return Scaffold(
      backgroundColor: NeumorphicDecorator.baseColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Header
            Text(
              'PITCH TIMER',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey.withOpacity(0.5),
                letterSpacing: 5,
              ),
            ),
            const Spacer(),

            // Central Ring/Timer
            GestureDetector(
              onTap: timerNotifier.toggle,
              onLongPress: timerNotifier.hardReset,
              child: HapticRingComponent(
                progress: timerState.progress,
                text: _formatTime(timerState.remainingSeconds),
              ),
            ),

            const Spacer(),

            // Footer Inputs with Depth-Recess Transition
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isIdle ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 500),
                scale: isIdle ? 1.0 : 0.8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Column(
                    children: [
                      Neumorphic(
                        style: NeumorphicDecorator.recessedStyle,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: TextField(
                          controller: _inputController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter Seconds',
                          ),
                          onChanged: (val) {
                            final sec = int.tryParse(val) ?? 0;
                            timerNotifier.setDuration(sec);
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      NeumorphicButton(
                        onPressed: () {
                          if (isIdle) {
                            final sec = int.tryParse(_inputController.text) ?? 60;
                            timerNotifier.setDuration(sec);
                            timerNotifier.start();
                          } else {
                            timerNotifier.toggle();
                          }
                        },
                        style: NeumorphicDecorator.standardStyle,
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                        child: Text(
                          isIdle ? 'START' : (timerState.status == TimerStatus.active ? 'PAUSE' : 'RESUME'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
