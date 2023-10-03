import 'package:flutter/material.dart';
import 'package:myCashBook/screens/history.dart';
import 'package:myCashBook/screens/home.dart';
import 'package:myCashBook/screens/login.dart';
import 'package:myCashBook/screens/input.dart';
import 'package:myCashBook/screens/settings.dart';
import 'package:myCashBook/services/authentication_service.dart';
import 'package:myCashBook/db/database.dart';
import 'package:myCashBook/services/data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseHelper = HiveDatabaseHelper();
  await databaseHelper.initDatabase();

  final authService = AuthenticationService(databaseHelper);
  final dataService = DataService(databaseHelper);
  final isLoggedIn = await authService.isUserLoggedIn();

  // Determine the initial route based on login status
  String initialRoute = isLoggedIn ? '/home' : '/login';

  runApp(
    MainApp(
      authService: authService,
      dataService: dataService,
      initialRoute: initialRoute,
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({
    Key? key,
    required this.authService,
    required this.dataService,
    required this.initialRoute,
  }) : super(key: key);

  final AuthenticationService authService;
  final DataService dataService;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'myCashBook',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      initialRoute:
          initialRoute, // Directly set initialRoute based on login status
      routes: {
        '/login': (context) => LoginScreen(authService: authService),
        '/home': (context) =>
            HomeScreen(authService: authService, dataService: dataService),
        '/add_transaction': (context) => AddTransactionScreen(
              transactionType: ModalRoute.of(context)!.settings.arguments,
              dataService: dataService,
            ),
        '/history': (context) => HistoryScreen(dataService: dataService),
        '/settings': (context) => SettingScreen(authService: authService),
      },
    );
  }
}
