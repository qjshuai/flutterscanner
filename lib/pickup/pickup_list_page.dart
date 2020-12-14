import 'package:cached_network_image/cached_network_image.dart';
import 'package:environment/service_center.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:quiver/strings.dart';
import 'package:scanner/pickup/pickup_dialog.dart';
import 'package:scanner/utils/constants.dart';
import 'package:scanner/utils/custom_color.dart';
import 'package:scanner/widgets/effect_inkwell.dart';
import 'package:scanner/widgets/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/error_envelope.dart';
import 'box.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class PickupListPage extends StatefulWidget {
  @override
  _PickupListPageState createState() => _PickupListPageState();
}

class _PickupListPageState extends State<PickupListPage> {
  String _lastKeywords;
  final _controller = TextEditingController();
  final _refreshController = RefreshController(initialRefresh: true);
  List<Box> _deliveries = [];

  int _lastPage;
  int _page = 1;
  int _total = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchPickupList() async {
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    final response = await http.get('/roshine/orden/selectReadyReceiveOrders',
        queryParameters: {
          'keyword': _controller.text ?? '',
          'pageNum': _page,
          'pageSize': 50
        });
    final boxes = ((response.data['data']) as List<dynamic>)
        .map((e) => Box.fromJson(e))
        .toList();
    final total = response.data['total'] as int;
    final pageNum = response.data['pageNum'] as int;
    return {'data': boxes, 'total': total, 'pageNum': pageNum};
  }

  void _onRefresh() async {
    _lastPage = _page;
    _page = 1;

    try {
      final result = await _fetchPickupList();
      _total = result['total'];
      final deliveries = result['data'];
      setState(() {
        _deliveries = deliveries;
      });
      _refreshController.refreshCompleted();
      if (_deliveries.length >= _total) {
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
    if (_deliveries.length >= _total) {
      _refreshController.refreshCompleted();
      _refreshController.loadNoData();
      return;
    }
    _lastPage = _page;
    _page += 1;
    try {
      final result = await _fetchPickupList();
      _total = result['total'];
      final deliveries = result['data'];
      if (deliveries.isEmpty) {
        _refreshController.loadNoData();
      } else {
        _refreshController.loadComplete();
        setState(() {
          _deliveries.addAll(deliveries);
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
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    print(bottom);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('待收件'),
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            image: DecorationImage(
              image: AssetImage(
                'assets/images/logo.png',
              ),
              alignment: Alignment(0, -0.65),
              fit: BoxFit.scaleDown,
              scale: 2.0,
            )),
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: CupertinoTextField(
                controller: _controller,
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                  if (_lastKeywords == _controller.text) {
                    return;
                  }
                  _lastKeywords = _controller.text;
                  _refreshController.requestRefresh();
                },
                placeholder: '请输入关键词检索',
                textAlign: TextAlign.center,
                cursorColor: Colors.white,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                placeholderStyle: TextStyle(
                  color: Colors.white.withAlpha(55),
                  fontSize: 15,
                ),
                decoration: BoxDecoration(
                    color: Color(0xFF3D5055),
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 10),
            Expanded(child: _buildPickupList(context))
          ],
        ),
      ),
    );
  }

  Widget _buildPickupList(BuildContext context) {
    return SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        header: ClassicHeader(),
        footer: ClassicFooter(),
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: _deliveries.isEmpty
            ? Center(
                child: Text(
                '无待收件',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ))
            : ListView.separated(
                separatorBuilder: (context, index) => SizedBox(
                      height: 10.0,
                    ),
                itemCount: _deliveries.length,
                itemBuilder: (context, index) {
                  final delivery = _deliveries[index];
                  return _buildCell(context, index, delivery);
                }));
  }

  Widget _buildCell(BuildContext context, int index, Box box) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: EffectInkWell(
        onTap: () async {
          if (box.status != 6 && box.status != 7) {
            showToast('非待收件或待揽收订单');
            return;
          }
          await showPickupDialog(context, box: box);
          if (box.needRefresh) {
            //更新数据
            box.needRefresh = false;
            _onRefresh();
          }
        },
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Container(
          height: 130.0,
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: CachedNetworkImage(
                            errorWidget: (context, _, __) =>
                                Container(color: Colors.grey),
                            imageUrl: box.headImgUrl ?? '',
                            width: 50.0,
                            height: 50.0,
                            fit: BoxFit.cover,
                          ),
                        )),
                    SizedBox(width: 10.0),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(box.nickname ?? '无',
                            style: Theme.of(context)
                                .primaryTextTheme
                                .bodyText1
                                .copyWith(
                                    color: CustomColor.darkTextColor,
                                    fontWeight: FontWeight.w500)),
                        Text(
                          box.subTitle ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Color(0xFF8C9C9D), fontSize: 11),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '服务码: ${box.orderCode}',
                          style: Theme.of(context)
                              .primaryTextTheme
                              .bodyText1
                              .copyWith(
                                  color: CustomColor.darkTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                        ),
                      ],
                    )),
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Color(0xFF263336),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              )),
                          width: 50,
                          height: 20,
                          margin: EdgeInsets.only(top: 15.0),
                          child: Center(
                            child: Text(
                              box.statusName ?? '未知',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                        CupertinoButton(
                            padding: EdgeInsets.zero,
                            // iconSize: 20,
                            child: Image.asset('assets/images/pickup_call.png',
                                width: 29, height: 29),
                            onPressed: () async {
                              if (box.tel == null || box.tel == '') {
                                showToast("该客户无号码");
                                return;
                              }
                              final scheme = 'tel:${box.tel}';
                              if (await canLaunch(scheme)) {
                                await launch(scheme);
                              } else {
                                showToast("不支持拨打电话");
                              }
                            })
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 0.5, color: Color(0xFFD2DDDD)),
              SizedBox(
                height: 50,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final address = box.address;
                    final latitude = double.tryParse(box.latitude);
                    final longitude = double.tryParse(box.longitude);
                    try {

                      if (latitude == null || longitude == null) {
                        // if (isEmpty(address)) {
                        showToast('终点坐标无效无效');
                        return;
                        // }
                        // showToast('终点坐标无效, 将根据地址查找路线, 请确认终点是否正确');
                        // nativeChannel.invokeMethod('launchRoute', {'latitude': latitude, 'longitude': longitude, 'address': address});
                      } else {
                        nativeChannel.invokeMethod('launchRoute', {
                          'latitude': latitude,
                          'longitude': longitude,
                          'address': address
                        });
                      }
                    } catch (e) {
                      showToast('启动导航失败, 请检查是否已安装导航软件');
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/address.png',
                          width: 15, height: 17),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          box.address ?? '无',
                          maxLines: 2,
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
