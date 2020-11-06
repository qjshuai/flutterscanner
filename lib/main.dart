import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanner/sign_dialog.dart';
import 'app_environment/environment.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_environment/environment_bloc.dart';
import 'app_environment/error_envelope.dart';
import 'order_dialog.dart';

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
        child: _requesting ? CupertinoActivityIndicator() :
        Column(
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
        onPressed: () => _signButtonPressed(context));
  }

  /// 点击扫码
  void _signButtonPressed(BuildContext context) async {
    try {
      String code = await _nativeChannel.invokeMethod('scan');
      setState((){
        _requesting = true;
      });
      final order = await BlocProvider.of<EnvironmentBloc>(context).fetchOrderInfo(code);
      final result = await showSignDetails(context, order, code);
      setState((){
        _requesting = false;
      });
      // if (result) {
      //   _signButtonPressed(context);
      // }
    } catch (error) {
      setState((){
        _requesting = false;
      });
      final msg = ErrorEnvelope(error).toString();
      if (msg.contains('已取消') && msg.contains('100')) {
        return;
      }
      _alertOk(context, msg);
      // await showToast();
    }
  }

  /// 点击签收
  void _scanButtonPressed(BuildContext context) async {
    try {
      String code = await _nativeChannel.invokeMethod('scan');
      setState((){
        _requesting = true;
      });
      final groups = await BlocProvider.of<EnvironmentBloc>(context)
          .fetchScannerInfo(code);
      final result = await showCongratulationDialog(context, groups);
      setState((){
        _requesting = false;
      });
      if (result) {
        _scanButtonPressed(context);
      }
    } catch (error) {
      setState((){
        _requesting = false;
      });
      final msg = ErrorEnvelope(error).toString();
      if (msg.contains('已取消') && msg.contains('100')) {
        return;
      }
      _alertOk(context, msg);
      // await showToast();
    }
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
