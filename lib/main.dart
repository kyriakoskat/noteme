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
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        '/login': (context) => SignInPage(),
        '/create-account': (context) => CreateAccountPage(),
        '/home': (context) => HomePage(),
      },
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/all-courses':
        final args = settings.arguments as List<String>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => AllCoursesPage(initialSubjects: args),
          );
        }
        return _errorRoute('Invalid or missing arguments for /all-courses.');

      case '/subject':
        final args = settings.arguments as Map?;
        if (args != null && args.containsKey('subjectName')) {
          return MaterialPageRoute(
            builder: (context) => SubjectPage(subjectName: args['subjectName']),
          );
        }
        return _errorRoute('Invalid or missing arguments for /subject.');

      default:
        return _errorRoute('Undefined route: ${settings.name}');
    }
  }

  MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
