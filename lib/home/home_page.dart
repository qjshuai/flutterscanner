import 'package:environment/service_center.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scanner/adjust/adjust_page.dart';
import 'package:scanner/home/site.dart';
import 'package:scanner/receipt/receipt_dialog.dart';
import 'package:scanner/send/send_dialog.dart';
import 'package:scanner/station_list_page.dart';
import 'package:scanner/receipt/receipt_info.dart';
import 'package:environment/error_wrapper.dart';

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

  Future<Map<String, dynamic>> _fetchSiteList() async {
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    final response = await http.get('/roshine/poststation/queryStationPage', queryParameters: {'pageNum': _page, 'pageSize': 50});
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
                Text(
                  '工具列表',
                  style: Theme.of(context).primaryTextTheme.headline4,
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
                              onPressed: () => showSendDialog(context))),
                      SizedBox(width: 18),
                      Expanded(
                          child: _buildToolItem(
                              context, '信息调整', 'assets/images/green_1.png',
                              onPressed: () => showAdjustDialog(context))),
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
        // header: WaterDropHeader(),
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
                        builder: (context) {
                          return DeliveryListPage(_sites[index]);
                        },
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
