import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanner/congratulation_dialog.dart';
import 'app_environment/environment.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_environment/environment_bloc.dart';

void main() async {
//  await initializeDateFormatting();
  WidgetsFlutterBinding.ensureInitialized();
//  BlocSupervisor.delegate = AppBlocDelegate();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final environmentBloc = await EnvironmentBloc.restore();
  try {
    runApp(MultiBlocProvider(
      providers: [
        BlocProvider<EnvironmentBloc>(
          create: (context) {
            return environmentBloc;
          },
        )
      ],
      child: MyApp(),
    ));
  } catch (e) {
    print(e);
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnvironmentBloc, Environment>(
      builder: (context, environment) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'WorkKing',
          theme: ThemeData(
            platform: TargetPlatform.iOS,
            primaryColor: environment.appearance.colorScheme.primary,
          ),
//          theme: ThemeData(
//            appBarTheme: AppBarTheme(
//              color: environment.appearance.colorScheme.primary,
////              elevation: 0,
//              textTheme: environment.appearance.textTheme,
//            ),
//            textTheme: environment.appearance.textTheme,
//            colorScheme: environment.appearance.colorScheme,
//            brightness: Brightness.light,
//            errorColor: environment.appearance.colorScheme.error,
//            backgroundColor: environment.appearance.colorScheme.background,
//            visualDensity: VisualDensity.adaptivePlatformDensity,
//            platform: TargetPlatform.iOS,
//          ),
          themeMode: ThemeMode.light,
          routes: {},
          home: HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  static const _nativeChannel = const MethodChannel('com.js.scanner');

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Color(0xFFDDDDDD),
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('扫码'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SizedBox(
          width: 180,
          height: 50,
          child: FlatButton(
              color: Theme.of(context).primaryColor,
              child: Text('开 始',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              onPressed: () => _scanButtonPressed(context)),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _scanButtonPressed(BuildContext context) async {
    try {
      String code = await _nativeChannel.invokeMethod('scan');
      final groups = await BlocProvider.of<EnvironmentBloc>(context).fetchScannerInfo(code);
      final result = await showCongratulationDialog(context, groups);
      if (result) {
        _scanButtonPressed(context);
      }
    } catch (error) {
      print(error);
    }
  }
}
