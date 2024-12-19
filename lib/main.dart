import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_page.dart';
import 'screens/sign_in_page.dart';
import 'screens/create_account_page.dart';
import 'screens/home_page.dart';
import 'screens/all_courses_page.dart';
import 'screens/subjects_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome App',
      theme: ThemeData(primarySwatch: Colors.purple),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        '/login': (context) => SignInPage(),
        '/create-account': (context) => CreateAccountPage(),
        '/home': (context) => HomePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/all-courses') {
          final args = settings.arguments as List<String>;
          return MaterialPageRoute(
            builder: (context) => AllCoursesPage(initialSubjects: args),
          );
        } else if (settings.name == '/subjects') {
          final args = settings.arguments as List<String>;
          return MaterialPageRoute(
            builder: (context) => SubjectsPage(subjects: args),
          );
        }
        return null; // If no matching route is found
      },
    );
  }
}
