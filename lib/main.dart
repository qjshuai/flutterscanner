import 'dart:async';

import 'package:environment/app_bloc.dart';
import 'package:environment/app_repository.dart';
import 'package:environment/app_state.dart';
import 'package:environment/database_type.dart';
import 'package:environment/environment.dart';
import 'package:environment/http.dart';
import 'package:environment/preference_type.dart';
import 'package:environment/service_center.dart';
import 'package:environment/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:scanner/sign_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'bloc_observer.dart';
import 'custom_color.dart';
import 'error_envelope.dart';
import 'home/home_page.dart';
import 'home_screen.dart';
import 'order_dialog.dart';

Future<List<BlocProvider>> setup() async {
  try {
    final preference = await SharedPreferences.getInstance();
    final preferenceBox = SharedPreferencesWrapper(preference);

    final settings = Settings(
        soundEnabled: false, fontScaleMode: FontScaleMode.system, locale: null);
    AppState defaultState;
    if (inProduction) {
      final env = Environment(
          name: 'production',
          baseUrl: 'https://wechat.roshinediy.com',
          isDebug: false,
          logMode: LogMode.none);
      defaultState = AppState(settings: settings, environment: env);
    } else {
      final env = Environment(
          name: 'development',
          baseUrl: 'http://172.16.178.16:8081',
          isDebug: true,
          logMode: LogMode.normal);
      defaultState = AppState(settings: settings, environment: env);
    }
    AppState appState = await AppRepository.fromStorage(preferenceBox);

    if (appState == null) {
      appState = defaultState;
    } else if (inProduction) {
      //生产环境使用默认环境设置
      appState = appState.update(environment: defaultState.environment);
    }
    final database = await openDatabase('data.db');
    final databaseWrapper = DatabaseWrapper(database);

    final getIt = GetIt.instance;
    if (inProduction) {
      getIt.registerSingleton<ServiceCenter>(
          ServiceCenter.production(appState, preferenceBox, databaseWrapper));
    } else {
      getIt.registerSingleton<ServiceCenter>(
          ServiceCenter.development(appState, preferenceBox, databaseWrapper));
    }
    final appBloc = AppBloc(appState);
    getIt.registerSingleton<AppBloc>(appBloc);

    return [
      BlocProvider<AppBloc>(
        create: (context) => appBloc,
      ),
    ];
  } catch (e) {
    print('error $e');
    await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    return null;
  }
}

Future<Null> main() async {
  /// 转发异常
  FlutterError.onError = (FlutterErrorDetails details) async {
    Zone.current.handleUncaughtError(details.exception, details.stack);
  };
  // debugPaintSizeEnabled = false;
  Bloc.observer = MyBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();

  final providers = await setup();

  final app = MultiBlocProvider(
    providers: providers,
    child: MyApp(),
  );

  runZonedGuarded(() => runApp(app), (Object error, StackTrace stackTrace) {
    if (!inProduction) {
      print(error);
      print(stackTrace);
      print('In dev mode. Not sending report to bugly');
      return;
    }
    try {
      // sentryClient.captureException(
      //   exception: error,
      //   stackTrace: stackTrace,
      // );
      print('Error sent to sentry.io: $error');
    } catch (e) {
      print('Sending report to sentry.io failed: $e');
      print('Original error: $error');
    }
  });
}

class MyApp extends StatefulWidget {
  final _navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'ServiceProviderState');

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  NavigatorState get _navigator => widget._navigatorKey.currentState;
  final getIt = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scanner',
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        primaryColor: CustomColor.primaryColor,
        primaryTextTheme: Typography.whiteCupertino.copyWith(
            headline4: TextStyle(
                fontSize: 25.0,
                color: Colors.white,
                fontWeight: FontWeight.w500),
            headline6: TextStyle( //bar
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.w500),
            subtitle1: TextStyle(
                fontSize: 15.0,
                color: Colors.white,
                fontWeight: FontWeight.w500),
            bodyText1: TextStyle(
                fontSize: 13.0,
                color: Color(0xFF8C9C9D),
                fontWeight: FontWeight.normal),
            bodyText2: TextStyle(
                fontSize: 11.0,
                color: Color(0xFF8C9C9D),
                fontWeight: FontWeight.normal)),
      ),
      themeMode: ThemeMode.light,
      home: HomePage(),
    );
  }
}

