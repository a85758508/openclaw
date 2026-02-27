import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/story_provider.dart';
import 'providers/voice_provider.dart';
import 'screens/home_screen.dart';
import 'services/openai_service.dart';
import 'services/story_storage_service.dart';
import 'services/voice_service.dart';

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
    final storage = StoryStorageService();
    final voiceService = VoiceService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VoiceProvider(voiceService: voiceService)..init(),
        ),
        ChangeNotifierProxyProvider<VoiceProvider, StoryProvider>(
          create: (_) => StoryProvider(
            openAIService: openAI,
            storageService: storage,
          )..loadStories(),
          update: (_, voiceProvider, storyProvider) {
            storyProvider!.updateVoiceId(voiceProvider.customVoiceId);
            return storyProvider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Yiheng Bedtime Stories',
        theme: base.copyWith(
          textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
