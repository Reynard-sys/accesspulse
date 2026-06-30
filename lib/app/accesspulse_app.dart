import 'package:flutter/material.dart';

import '../config/ai_config.dart';
import '../data/in_memory_accesspulse_repository.dart';
import '../domain/accesspulse_domain.dart';
import '../features/institution/institution_flow.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/public/public_flow.dart';

class AccessPulseApp extends StatefulWidget {
  const AccessPulseApp({
    this.showOnboarding = true,
    super.key,
  });

  final bool showOnboarding;

  @override
  State<AccessPulseApp> createState() => _AccessPulseAppState();
}

class _AccessPulseAppState extends State<AccessPulseApp> {
  late final InMemoryAccessPulseRepository _repository;
  late final DimensionStateService _stateService;
  late final AiEvidenceService _aiService;
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
    _repository = InMemoryAccessPulseRepository.seeded();
    _stateService = DimensionStateService(repository: _repository);
    _aiService = AiConfig.fromEnvironment.hasServerWrapper
        ? GeminiServerEvidenceService(
            functionUri: Uri.parse(AiConfig.fromEnvironment.functionUrl),
            supabaseAnonKey: AiConfig.fromEnvironment.supabaseAnonKey,
          )
        : const MockAiEvidenceService();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AccessPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff27665f),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7f9f8),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xffdbe4e0)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      home: _showOnboarding
          ? OnboardingScreen(
              onCompleted: () {
                setState(() {
                  _showOnboarding = false;
                });
              },
            )
          : _AccessPulseRoleShell(
              repository: _repository,
              stateService: _stateService,
              aiService: _aiService,
            ),
    );
  }
}

class _AccessPulseRoleShell extends StatefulWidget {
  const _AccessPulseRoleShell({
    required this.repository,
    required this.stateService,
    required this.aiService,
  });

  final AccessPulseRepository repository;
  final DimensionStateService stateService;
  final AiEvidenceService aiService;

  @override
  State<_AccessPulseRoleShell> createState() => _AccessPulseRoleShellState();
}

class _AccessPulseRoleShellState extends State<_AccessPulseRoleShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final body = switch (_selectedIndex) {
      0 => PublicHomeScreen(
        repository: widget.repository,
        stateService: widget.stateService,
        aiService: widget.aiService,
      ),
      1 => InstitutionDashboardScreen(
        repository: widget.repository,
        stateService: widget.stateService,
        role: InstitutionRole.lguReviewer,
      ),
      _ => InstitutionDashboardScreen(
        repository: widget.repository,
        stateService: widget.stateService,
        role: InstitutionRole.inspector,
      ),
    };

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.01, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey(_selectedIndex), child: body),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.public), label: 'Public'),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'LGU',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            label: 'Inspector',
          ),
        ],
      ),
    );
  }
}
