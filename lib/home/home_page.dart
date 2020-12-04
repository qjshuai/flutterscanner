import 'package:environment/service_center.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:quiver/strings.dart';
import 'package:scanner/delivery/delivery_list_page.dart';
import 'package:scanner/home/site.dart';
import 'package:scanner/input/input_adjust.dart';
import 'package:scanner/input/input_order.dart';
import 'package:scanner/receipt/receipt_dialog.dart';
import 'package:scanner/send/send_dialog.dart';
import 'package:environment/error_wrapper.dart';
import 'package:package_info/package_info.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RefreshController _refreshController =
      RefreshController(initialRefresh: true);
  List<Site> _sites = [];

  int _page = 1;
  int _total = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkForUpdate();
  }

  void _checkForUpdate() async {
    final package = await PackageInfo.fromPlatform();
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    String appKey;
    if (Platform.isIOS) {
      appKey = 'f3c723341409b2cf6eff516670fd8a18';
    } else {
      appKey = '7679feb3f8e224230741ffd89a221d12';
    }
    final buildNumber = package.buildNumber;
    final response = await http.post('https://www.pgyer.com/apiv2/app/view', data: {
      '_api_key': '13c2602c5d29dd38b4502e9a47a24dcc',
      'appKey': appKey,
      'buildVersion': buildNumber
    },
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );
    final data = response.data['data'];
    final build = int.tryParse(buildNumber);
    final serverBuild = int.tryParse((data['buildVersionNo'] as String));
    final url = data['buildShortcutUrl'] as String;
    final hasNew = serverBuild != null && serverBuild > build;
    if (hasNew) {
      final preference = await SharedPreferences.getInstance();
      final lastReject = preference.getString('lastReject');
      if (lastReject != null) {
        final date = DateTime.tryParse(lastReject);
        if (date.month == DateTime.now().month && date.day == DateTime.now().day) {
          return;
        }
      }
      _alertUpdate(url);
    }
  }

  final _format = DateFormat('yyyy-MM-dd');

  void _alertUpdate(String url) {
    final dialog = CupertinoAlertDialog(
      title: Text(
        '检测到新版本, 是否下载新版本?',
        style: TextStyle(fontSize: 20),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          child: Text('取消'),
          onPressed: () {
            Navigator.pop(context);
            //记录拒绝时间
            SharedPreferences.getInstance().then((value) {
              value.setString('lastReject', _format.format(DateTime.now()));
            });
          },
        ),
        CupertinoDialogAction(
          child: Text('确定'),
          onPressed: () {
            if (Platform.isIOS) {
              launch('https://www.pgyer.com/rnNY', forceSafariVC: true);
            } else {
              launch('https://www.pgyer.com/4PvO');
            }
            Navigator.pop(context);
          },
        ),
      ],
    );
    showCupertinoDialog(context: context, builder: (_) => dialog);
  }

  Future<Map<String, dynamic>> _fetchSiteList() async {
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    final response = await http.get('/roshine/poststation/queryStationPage',
        queryParameters: {'pageNum': _page, 'pageSize': 50});
    final sites = ((response.data['data']) as List<dynamic>)
        .map((e) => Site.fromJson(e))
        .toList();
    final total = response.data['total'] as int;
    final pageNum = response.data['pageNum'] as int;
    return {'data': sites, 'total': total, 'pageNum': pageNum};
  }

  void _onRefresh() async {
    _page = 1;
    setState(() {
      _sites = [];
    });
    try {
      final result = await _fetchSiteList();
      _total = result['total'];
      final sites = result['data'];
      setState(() {
        _sites = sites;
      });
      _refreshController.refreshCompleted();
      if (_sites.length >= _total) {
        _refreshController.loadNoData();
      }
    } catch (e) {
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: ErrorEnvelope(e).toString());
      _refreshController.refreshFailed();
    }
  }

  void _onLoading() async {
    if (_sites.length >= _total) {
      _refreshController.refreshCompleted();
      _refreshController.loadNoData();
      return;
    }
    _page += 1;
    try {
      final result = await _fetchSiteList();
      _total = result['total'];
      final sites = result['data'];
      if (sites.isEmpty) {
        _refreshController.loadNoData();
      } else {
        _refreshController.loadComplete();
        setState(() {
          _sites.addAll(sites);
        });
      }
    } catch (e) {
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: ErrorEnvelope(e).toString());
      _page -= 1;
      _refreshController.loadFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('扫码'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
            image: AssetImage(
              'assets/images/logo.png',
            ),
            alignment: Alignment(0, -0.65),
            scale: 2.0,
          )),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '工具列表',
                      style: Theme.of(context).primaryTextTheme.headline4,
                    ),
                    CupertinoButton(child: Row(
                      children: [
                        Icon(Icons.edit_sharp, color: Colors.white, size: 15.0),
                        SizedBox(width: 5),
                        Text(
                          '手动录入',
                          style: TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ), onPressed: () => _startInput(context)),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  height: 120.0,
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildToolItem(
                              context, '洁衣', 'assets/images/green_3.png',
                              onPressed: () => showReceiptDialog(context))),
                      SizedBox(width: 18),
                      Expanded(
                          child: _buildToolItem(
                              context, '派送', 'assets/images/green_2.png',
                              onPressed: () =>
                                  showSendDialog(context, SendMode.send))),
                      SizedBox(width: 18),
                      Expanded(
                          child: _buildToolItem(
                              context, '信息调整', 'assets/images/green_1.png',
                              onPressed: () =>
                                  showSendDialog(context, SendMode.adjust))),
                    ],
                  ),
                ),
                SizedBox(
                  height: 30.0,
                ),
                Text(
                  '驿站列表',
                  style: Theme.of(context).primaryTextTheme.headline4,
                ),
                SizedBox(
                  height: 20.0,
                ),
                Expanded(child: _buildStationList(context))
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startInput(BuildContext context) async {
    final code = await showInputOrderDialog(context);
    if (isNotEmpty(code)) {
      final result = await showInputAdjustDialog(context, code);
      if (result) {
        _startInput(context);
      }
    }
  }

  /// 上方工具栏
  Widget _buildToolItem(BuildContext context, String title, String icon,
      {Function() onPressed}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
            scale: 2.0,
            image: AssetImage(icon),
          )),
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 13.0),
              Image.asset(
                'assets/images/scan.png',
                scale: 2.0,
                width: 45.0,
                height: 45.0,
              ),
              SizedBox(height: 13.0),
              Text(
                title,
                style: Theme.of(context).primaryTextTheme.subtitle1,
              )
            ],
          ))),
    );
  }

  /// 站点列表
  Widget _buildStationList(BuildContext context) {
    return SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        header: ClassicHeader(),
        footer: ClassicFooter(),
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: ListView.builder(
            itemExtent: 60.0,
            itemCount: _sites.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  if ((_sites[index].readyReceive ?? 0) < 1) {
                    Fluttertoast.cancel();
                    Fluttertoast.showToast(
                        msg: '无待取件', gravity: ToastGravity.CENTER);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => DeliveryListPage(_sites[index]),
                        settings: RouteSettings(arguments: 1)),
                  );
                },
                child: Column(
                  children: [
                    Expanded(
                        child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 14.0),
                        child: Row(
                          children: [
                            Text(
                              _sites[index].stationName,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  .copyWith(color: Color(0xFF263336)),
                            ),
                            Spacer(),
                            Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: '待取件 ',
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText2),
                              TextSpan(
                                  text: '${_sites[index].readyReceive}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .copyWith(color: Color(0xFFD43969))),
                              TextSpan(
                                  text: ' 件',
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText2),
                            ])),
                            SizedBox(width: 10.0),
                            Icon(
                              Icons.arrow_forward_ios_sharp,
                              size: 11,
                            )
                          ],
                        ),
                      ),
                    )),
                    SizedBox(height: 10.0)
                  ],
                ),
              );
            }));
  }
}
