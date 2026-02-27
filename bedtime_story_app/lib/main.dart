import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'providers/story_provider.dart';
import 'providers/voice_provider.dart';
import 'screens/home_screen.dart';
import 'services/elevenlabs_service.dart';
import 'services/openai_service.dart';
import 'services/story_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BedtimeStoryApp());
}

class BedtimeStoryApp extends StatelessWidget {
  const BedtimeStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6EC6FF)),
      useMaterial3: true,
    );

    final openAI = OpenAIService();
    final elevenlabs = ElevenLabsService();
    final storage = StoryStorageService();

    return MultiProvider(
      providers: [
        // Make ElevenLabsService available for VoiceSetupScreen preview
        Provider.value(value: elevenlabs),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => VoiceProvider(elevenlabsService: elevenlabs)..init(),
        ),
        ChangeNotifierProxyProvider2<VoiceProvider, SettingsProvider,
            StoryProvider>(
          create: (_) => StoryProvider(
            openAIService: openAI,
            elevenlabsService: elevenlabs,
            storageService: storage,
          )..loadStories(),
          update: (_, voiceProvider, settingsProvider, storyProvider) {
            storyProvider!
              ..updateVoiceEnabled(voiceProvider.shouldUseCustomVoice)
              ..updateChildName(settingsProvider.childName);
            return storyProvider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bedtime Stories',
        theme: base.copyWith(
          textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
