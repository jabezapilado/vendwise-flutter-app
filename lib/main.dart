import 'package:flutter/material.dart';
import 'package:vendwise/backend/bootstrap.dart';
import 'package:vendwise/screens/auth/splash_screen.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrapResult = await initializeBackend();
  if (!bootstrapResult.supabaseReady) {
    debugPrint(
      'Backend startup using mock data: '
      '${bootstrapResult.describeIssues()}',
    );
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Exploring Flutter UI Widgets",
      theme: ThemeData(fontFamily: 'Inter'),
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            currentFocus.unfocus();
          }
        },
        child: child ?? const SizedBox.shrink(),
      ),
      home: const Splashscreen(),
    ),
  );
}
