import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff2e7d5b),
        primary: const Color(0xff2e7d5b),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xfff8faf9),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xffdde5e0), width: 1.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xff17201c)),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xffdde5e0),
            width: 1.5,
          ),
        ),
        titleTextStyle: GoogleFonts.afacad(
          color: const Color(0xff17201c),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xffe8eee9),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.afacad(
              color: const Color(0xff2e7d5b),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return GoogleFonts.afacad(
            color: const Color(0xff5d6b63),
            fontWeight: FontWeight.normal,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xff2e7d5b), size: 24);
          }
          return const IconThemeData(color: Color(0xff5d6b63), size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xffe8eee9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff2e7d5b), width: 1.5),
        ),
        labelStyle: GoogleFonts.afacad(
          color: const Color(0xff5d6b63),
          fontSize: 16,
        ),
        hintStyle: GoogleFonts.afacad(
          color: const Color(0xff5d6b63),
          fontSize: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xff2e7d5b),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.afacad(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff2e7d5b),
          side: const BorderSide(color: Color(0xff2e7d5b), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.afacad(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xff5d6b63),
          textStyle: GoogleFonts.afacad(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    return MaterialApp(
      title: 'AccessPulse',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.afacadTextTheme(baseTheme.textTheme),
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
        hideAppBar: true,
      ),
      1 => InstitutionDashboardScreen(
        repository: widget.repository,
        stateService: widget.stateService,
        role: InstitutionRole.lguReviewer,
        hideAppBar: true,
      ),
      _ => InstitutionDashboardScreen(
        repository: widget.repository,
        stateService: widget.stateService,
        role: InstitutionRole.inspector,
        hideAppBar: true,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const _AccessPulseBrandTitle(fontSize: 24),
      ),
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

class _AccessPulseBrandTitle extends StatelessWidget {
  const _AccessPulseBrandTitle({this.fontSize = 20, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Access',
            style: GoogleFonts.afacad(
              color: const Color(0xff17201c),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: 'Pulse',
            style: GoogleFonts.afacad(
              color: const Color(0xff2e7d5b),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: fontSize,
        letterSpacing: -0.5,
      ),
    );
  }
}
