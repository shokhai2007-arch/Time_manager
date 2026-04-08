import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timer_controller.dart';
import 'decorators.dart';
import 'widgets/haptic_ring.dart';
import 'updater.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
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
  final TextEditingController _totalTimeController =
      TextEditingController(text: '60');
  final TextEditingController _periodTimeController =
      TextEditingController(text: '10');

  void _checkUpdates() async {
    final hasUpdate = await AutoUpdater.checkForUpdates();
    if (!mounted) return;
    if (hasUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yangilanish topildi va yuklanmoqda...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oxirgi versiyadan foydalanyapsiz.')),
      );
    }
  }

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
            const SizedBox(height: 20),
            // Header (Tier 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Balance for icon button
                Text(
                  'TIME MANAGEMENT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey.withValues(alpha: 0.5),
                    letterSpacing: 2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.system_update_alt,
                      color: Colors.blueGrey),
                  onPressed: _checkUpdates,
                  tooltip: 'Check for updates',
                ),
              ],
            ),
            const Spacer(),

            // Central Ring/Timer (Tier 2)
            GestureDetector(
              onTap: timerNotifier.toggle,
              onLongPress: timerNotifier.hardReset,
              child: HapticRingComponent(
                progress: timerState.periodProgress,
                text: _formatTime(timerState.remainingTotalSeconds),
              ),
            ),

            const Spacer(),

            // Footer Inputs with Depth-Recess Transition (Tier 3)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isIdle ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 500),
                scale: isIdle ? 1.0 : 0.8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Neumorphic(
                              style: NeumorphicDecorator.recessedStyle,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: TextField(
                                controller: _totalTimeController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Total (s)',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Neumorphic(
                              style: NeumorphicDecorator.recessedStyle,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: TextField(
                                controller: _periodTimeController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Period (s)',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      NeumorphicButton(
                        onPressed: () {
                          if (isIdle) {
                            final total =
                                int.tryParse(_totalTimeController.text) ?? 60;
                            final period =
                                int.tryParse(_periodTimeController.text) ?? 10;
                            timerNotifier.setDurations(total, period);
                            timerNotifier.start();
                          } else {
                            timerNotifier.toggle();
                          }
                        },
                        style: NeumorphicDecorator.standardStyle,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 15,
                        ),
                        child: Text(
                          isIdle
                              ? 'START'
                              : (timerState.status == TimerStatus.active
                                  ? 'PAUSE'
                                  : 'RESUME'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
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
