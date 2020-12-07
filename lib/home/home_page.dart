import 'package:environment/service_center.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:quiver/strings.dart';
import 'package:scanner/delivery/delivery_list_page.dart';
import 'package:scanner/home/print_dialog.dart';
import 'package:scanner/home/site.dart';
import 'package:scanner/input/input_adjust.dart';
import 'package:scanner/input/input_order.dart';
import 'package:scanner/receipt/receipt_dialog.dart';
import 'package:scanner/send/send_dialog.dart';
import 'package:environment/error_wrapper.dart';
import 'package:package_info/package_info.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:scanner/widgets/toast.dart';
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

  int _lastPage;
  int _page = 1;
  int _total = 0;

  @override
  void initState() {
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
    final response = await http.post(
      'https://www.pgyer.com/apiv2/app/view',
      data: {
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
        if (date.month == DateTime.now().month &&
            date.day == DateTime.now().day) {
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
    _lastPage = _page;
    _page = 1;
    // setState(() {
    //   _sites = [];
    // });
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
      _page = _lastPage;
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
    _lastPage = _page;
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
      _page = _lastPage;
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
          height: double.infinity,
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildStationList(context)),
        ),
      ),
    );
  }

  void _startPrint(BuildContext context) {
    showPrintDialog(context);
  }

  /// 上方工具栏
  Widget _buildToolItem(
      BuildContext context, String title, int index, String icon,
      {Function() onPressed}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: AspectRatio(
        aspectRatio: 1.25,
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                image: DecorationImage(
                    scale: 2.0,
                    image: AssetImage('assets/images/bg_$index.png'),
                    fit: BoxFit.cover)),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 13.0),
                Image.asset(
                  icon,
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 10.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '工具列表',
              style: Theme.of(context).primaryTextTheme.headline4,
            ),
            // CupertinoButton(
            //     child: Row(
            //       children: [
            //         Image.asset('assets/images/print.png',
            //             color: Colors.white, width: 15.0, height: 15.0),
            //         SizedBox(width: 5),
            //         Text(
            //           '打印',
            //           style: TextStyle(
            //               color: Colors.white,
            //               fontSize: 13.0,
            //               fontWeight: FontWeight.w500),
            //         ),
            //       ],
            //     ),
            //     onPressed: () => _startPrint(context)),
          ],
        ),
        SizedBox(height: 20.0),
        SizedBox(
          child: Column(
              // mainAxisSize: MainAxisSize.max,
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildToolItem(
                            context, '洁衣', 1, 'assets/images/scan.png',
                            onPressed: () => showReceiptDialog(context))),
                    SizedBox(
                      width: 15.0,
                    ),
                    Expanded(
                        child: _buildToolItem(
                            context, '派送', 2, 'assets/images/scan.png',
                            onPressed: () =>
                                showSendDialog(context, SendMode.send))),
                  ],
                  mainAxisSize: MainAxisSize.max,
                  // crossAxisAlignment: CrossAxisAlignment.stretch,
                ),
                SizedBox(
                  height: 15.0,
                ),
                Row(
                  children: [
                    Expanded(
                        child: _buildToolItem(
                            context, '信息调整', 3, 'assets/images/scan.png',
                            onPressed: () =>
                                showSendDialog(context, SendMode.adjust))),
                    SizedBox(
                      width: 15.0,
                    ),
                    Expanded(
                        child: _buildToolItem(
                            context, '待收件', 4, 'assets/images/box.png',
                            onPressed: () => showToast('尚不支持该功能'))),
                  ],
                )
              ]),
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
        )
      ],
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
            itemCount: _sites.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildHeader(context);
              } else {
                return InkWell(
                  onTap: () async {
                    if ((_sites[index - 1].readyReceive ?? 0) < 1) {
                      Fluttertoast.cancel();
                      Fluttertoast.showToast(
                          msg: '无待取件', gravity: ToastGravity.CENTER);
                      return;
                    }
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) =>
                              DeliveryListPage(_sites[index - 1]),
                          settings: RouteSettings(arguments: 1)),
                    );
                    _onRefresh();
                  },
                  child: Column(
                    children: [
                      SizedBox(
                          height: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 14.0),
                              child: Row(
                                children: [
                                  Text(
                                    _sites[index - 1].stationName,
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
                                        text:
                                            '${_sites[index - 1].readyReceive}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .copyWith(
                                                color: Color(0xFFD43969))),
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
              }
            }));
  }
}
