import 'package:flutter/material.dart';

import '../data/in_memory_accesspulse_repository.dart';
import '../domain/accesspulse_domain.dart';
import '../features/public/public_flow.dart';

class AccessPulseApp extends StatefulWidget {
  const AccessPulseApp({super.key});

  @override
  State<AccessPulseApp> createState() => _AccessPulseAppState();
}

class _AccessPulseAppState extends State<AccessPulseApp> {
  late final InMemoryAccessPulseRepository _repository;
  late final DimensionStateService _stateService;
  late final AiEvidenceService _aiService;

  @override
  void initState() {
    super.initState();
    _repository = InMemoryAccessPulseRepository.seeded();
    _stateService = DimensionStateService(repository: _repository);
    _aiService = const MockAiEvidenceService();
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
      home: PublicHomeScreen(
        repository: _repository,
        stateService: _stateService,
        aiService: _aiService,
      ),
    );
  }
}
