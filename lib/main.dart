import 'package:flutter/material.dart';
import 'package:notchai_frontend/provider/scan_tech_provider.dart';
import 'package:notchai_frontend/screens/bottom_navigation.dart';
import 'package:notchai_frontend/utils/app_styles.dart';
import 'package:notchai_frontend/provider/chats_provider.dart';
import 'package:notchai_frontend/provider/models_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ModelsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
         ChangeNotifierProvider(
          create: (_) => ScanTechProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NotchAI',
        theme: ThemeData(
          primaryColor: primary,
        ),
        home: const BottomNavBar(),
      ),
    );
  }
}
