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
import 'error_envelope.dart';
import 'order_dialog.dart';

Future<List<BlocProvider>> setup() async {
  try {
    final preference = await SharedPreferences.getInstance();
    final preferenceBox = SharedPreferencesWrapper(preference);
    // await AppRepository.clearStateIn(preferenceBox);

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

    // appState = appState.update(environment: appState.environment.copyWith(logMode: LogMode.none));

    if (appState == null) {
      appState = defaultState;
    } else if (inProduction) {
      //生产环境使用默认环境设置
      appState = appState.update(environment: defaultState.environment);
    }
    // final databasePath = await getDatabasesPath() + '';
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
  // await initializeDateFormatting();
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
        primaryColor: Colors.indigo,
      ),
      themeMode: ThemeMode.light,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _nativeChannel = const MethodChannel('com.js.scanner');

  bool _requesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDDDDDD),
      appBar: AppBar(
        title: Text('扫码'),
      ),
      body: Center(
        child: _requesting
            ? CupertinoActivityIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 50,
                    child: _buildScanButton(context),
                  ),
                  SizedBox(height: 50),
                  SizedBox(
                    width: 180,
                    height: 50,
                    child: _buildSignButton(context),
                  )
                ],
              ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  /// 收件
  Widget _buildScanButton(BuildContext context) {
    return FlatButton(
        color: Theme.of(context).primaryColor,
        child: Text('收 件', style: TextStyle(color: Colors.white, fontSize: 18)),
        onPressed: () => _scanButtonPressed(context));
  }

  /// 入库
  Widget _buildSignButton(BuildContext context) {
    return FlatButton(
        color: Theme.of(context).primaryColor,
        child: Text('入 库', style: TextStyle(color: Colors.white, fontSize: 18)),
        onPressed: () => showPutIn(context));
  }

  /// 点击签收
  void _scanButtonPressed(BuildContext context) async {
    // try {
    //   String code = await _nativeChannel.invokeMethod('scan');
    //   setState(() {
    //     _requesting = true;
    //   });
    //   final groups = await BlocProvider.of<EnvironmentBloc>(context)
    //       .fetchScannerInfo(code);
    //   final result = await showCongratulationDialog(context, groups);
    //   setState(() {
    //     _requesting = false;
    //   });
    //   if (result) {
    //     _scanButtonPressed(context);
    //   }
    // } catch (error) {
    //   setState(() {
    //     _requesting = false;
    //   });
    //   final msg = ErrorEnvelope(error).toString();
    //   if (msg.contains('已取消') && msg.contains('100')) {
    //     return;
    //   }
    //   _alertOk(context, msg);
    //   // await showToast();
    // }
  }

  /// 确定
  void _alertOk(BuildContext context, String message) {
    var dialog = CupertinoAlertDialog(
      content: Text(
        message,
        style: TextStyle(fontSize: 20),
      ),
      actions: <Widget>[
        CupertinoButton(
          child: Text('知道了'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
    showDialog<dynamic>(context: context, builder: (_) => dialog);
  }
}
