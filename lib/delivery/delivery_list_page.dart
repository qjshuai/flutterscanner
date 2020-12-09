import 'package:cached_network_image/cached_network_image.dart';
import 'package:environment/service_center.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scanner/input/input_adjust.dart';
import 'package:scanner/send/send_dialog.dart';
import 'package:scanner/utils/custom_color.dart';
import 'package:scanner/home/site.dart';
import 'package:scanner/widgets/CommonInkWell.dart';
import 'package:scanner/widgets/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'delivery.dart';
import '../utils/error_envelope.dart';

class DeliveryListPage extends StatefulWidget {
  final Site site;

  DeliveryListPage(this.site);

  @override
  _DeliveryListPageState createState() => _DeliveryListPageState();
}

class _DeliveryListPageState extends State<DeliveryListPage> {
  RefreshController _refreshController =
      RefreshController(initialRefresh: true);
  List<Delivery> _deliveries = [];

  int _page = 1;
  int _total = 0;
  bool isSending = false;
  bool isChanged = false;

  Future<Map<String, dynamic>> _fetchSiteList() async {
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    final response = await http
        .get('/roshine/poststation/selectReadyReceiveV2', queryParameters: {
      'stationId': widget.site.id,
      // 'pageNum': _page,
      // 'pageSize': 50
    });
    final sites = ((response.data['data']) as List<dynamic>)
        .map((e) => Delivery.fromJson(e))
        .toList();
    final total = response.data['total'] as int;
    final pageNum = response.data['pageNum'] as int;
    return {'data': sites, 'total': total, 'pageNum': pageNum};
  }

  void _onRefresh() async {
    _page = 1;
    // setState(() {
    //   _deliveries = [];
    // });
    try {
      final result = await _fetchSiteList();
      // _total = result['total'];
      final deliveries = result['data'];
      setState(() {
        _deliveries = deliveries;
        if (_deliveries.isEmpty) {
          _isEditing = false;
        }
      });
      _refreshController.refreshCompleted();
      // if (_deliveries.length >= _total) {
      //   _refreshController.loadNoData();
      // }

    } catch (e) {
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: ErrorEnvelope(e).toString());
      _refreshController.refreshFailed();
    }
  }

  void _submitOrders() async {
    _deliveries.forEach((element) {
      print(element.type);
    });
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    final alreadyOrderIds = _deliveries
            .where((element) => element.isSelected && element.type == 1)
            .map((e) => e.id)
            .toList() ??
        [];
    final readyOrderIds = _deliveries
            .where((element) => element.isSelected && element.type == 2)
            .map((e) => e.id)
            .toList() ??
        [];
    if (alreadyOrderIds.isEmpty && readyOrderIds.isEmpty) {
      showToast('无可揽收件');
      return;
    }
    setState(() {
      isSending = true;
    });
    try {
      final response = await http
          .get('/roshine/parcelorden/dealOrderAwayTime', queryParameters: {
        'alreadyOrderIds': alreadyOrderIds.join(','),
        'readyOrderIds': readyOrderIds.join(','),
        'stationId': widget.site.id
      });
      final code = response.data['code'] as int;
      if (code == 0) {
        _onRefresh();
      } else {
        showToast('错误');
        var message = response.data['message'] as String;
        if (message == null || message == '') {
          message = '错误 code :${code ?? 999}';
        }
      }
    } catch (e) {
      showToast(ErrorEnvelope(e).toString());
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _onLoading() async {
    if (_deliveries.length >= _total) {
      _refreshController.refreshCompleted();
      _refreshController.loadNoData();
      return;
    }
    _page += 1;
    try {
      final result = await _fetchSiteList();
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
      _page -= 1;
      _refreshController.loadFailed();
    }
  }

  bool _isEditing = false;

  bool get isSelectedAll =>
      _deliveries.where((element) => !element.isSelected).isEmpty;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    print(bottom);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.site.stationName}-待揽收'),
        elevation: 0,
        actions: [
          CupertinoButton(
              padding: EdgeInsets.only(right: 20),
              child: Text(
                _isEditing ? '取消' : '选择',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              onPressed: () {
                setState(() {
                  if (!_isEditing && _deliveries.isEmpty) {
                    showToast('无可揽收件');
                    return;
                  }
                  this._isEditing = !this._isEditing;
                  if (!_isEditing) {
                    _deliveries.forEach((element) {
                      element.isSelected = false;
                    });
                  }
                });
              })
        ],
      ),
      body: Stack(
        children: [
          Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/logo.png',
                    ),
                    alignment: Alignment(0, -0.65),
                    scale: 2.0,
                  ))),
          AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: 0,
              right: 0,
              bottom: _isEditing ? bottom + 60 : 0,
              top: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: _buildStationList(context),
              )),
          AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              child: _buildBottomBar(context),
              left: 0,
              right: 0,
              bottom: _isEditing ? 0 : -150,
              height: bottom + 60)
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        color: Colors.white,
        child: Row(
          children: [
            CupertinoButton(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                child: Row(
                  children: [
                    Icon(
                      isSelectedAll
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 15.0),
                    Text(
                      isSelectedAll ? '取消全选' : '全选',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500),
                    )
                  ],
                ),
                onPressed: () {
                  final isSelectedAll = this.isSelectedAll;
                  setState(() {
                    _deliveries.forEach((element) {
                      element.isSelected = !isSelectedAll;
                    });
                  });
                }),
            Spacer(),
            CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: isSending
                    ? null
                    : () {
                        setState(() {
                          _submitOrders();
                        });
                      },
                child: Container(
                  width: 110,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSending
                        ? Color(0xFF295B55).withAlpha(150)
                        : Color(0xFF295B55),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: isSending
                      ? CupertinoActivityIndicator()
                      : Center(
                          child: Text(
                          '揽收',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500),
                        )),
                ))
          ],
        ));
  }

  Widget _buildStationList(BuildContext context) {
    return SmartRefresher(
        enablePullDown: true,
        // enablePullUp: true,
        header: ClassicHeader(),
        // footer: ClassicFooter(),
        controller: _refreshController,
        onRefresh: _onRefresh,
        // onLoading: _onLoading,
        child: _deliveries.isEmpty
            ? Center(
                child: Text(
                '无待揽收件',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ))
            : ListView.separated(
                separatorBuilder: (context, index) => SizedBox(
                      height: 10.0,
                    ),
                // itemExtent: 90.0,
                itemCount: _deliveries.length,
                itemBuilder: (context, index) {
                  final delivery = _deliveries[index];
                  return _buildCell(context, index, delivery);
                }));
  }

  Widget _buildCell(BuildContext context, int index, Delivery delivery) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      secondaryActions: <Widget>[
        SlideAction(
            color: Theme.of(context).primaryColor,
            child: Image.asset(
              'assets/images/edit.png',
              width: 36,
              height: 36,
            ),
            onTap: () async {
              // if (delivery.orderCode == null || delivery.orderCode == '') {
              //   showToast("无订单号码");
              //   return;
              // }
              showInputAdjustDialog(context, delivery.orderCode);
            }),
        SlideAction(
          color: Theme.of(context).primaryColor,
          child: Image.asset(
            'assets/images/call.png',
            width: 80,
            height: 80,
          ),
          onTap: () async {
            if (delivery.tel == null || delivery.tel == '') {
              showToast("该客户无号码");
              return;
            }
            final scheme = 'tel:${delivery.tel}';
            if (await canLaunch(scheme)) {
              await launch(scheme);
            } else {
              showToast("不支持拨打电话");
            }
          },
        ),
      ],
      child: CommonInkWell(
        onTap: () {
          setState(() {
            _isEditing = true;
            delivery.isSelected = !delivery.isSelected;
          });
        },
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color:
                  delivery.isSelected ? Color(0xFFFE5D01) : Colors.transparent,
              width: 2),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          height: 84.0,
          padding: EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      errorWidget: (context, _, __) =>
                          Container(color: Colors.grey),
                      imageUrl: delivery.headImgUrl ?? '',
                      width: 50.0,
                      height: 50.0,
                      fit: BoxFit.cover,
                    ),
                    delivery.isSelected
                        ? Container(
                            width: 50.0,
                            height: 50.0,
                            color: Colors.black.withAlpha(80),
                            child: Center(
                              child: Image.asset(
                                  'assets/images/cell_selected.png',
                                  width: 20,
                                  height: 20),
                            ),
                          )
                        : Container(
                            width: 50.0,
                            height: 50.0,
                          )
                  ],
                ),
              ),
              SizedBox(width: 10.0),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: [
                  Text(delivery.nickname ?? '',
                      style: Theme.of(context)
                          .primaryTextTheme
                          .bodyText1
                          .copyWith(
                              color: CustomColor.darkTextColor,
                              fontWeight: FontWeight.w500)),
                  Text(
                    delivery.subTitle ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF8C9C9D), fontSize: 11),
                  ),
                  Text(
                    delivery.createtime ?? '',
                    style: TextStyle(color: Color(0xFFB8C8C5), fontSize: 10),
                  ),
                ],
              )),
              // Spacer(),
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
                        delivery.statusName ?? '未知',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/**
 *
 * CupertinoButton(
    child: Row(
    children: [
    Icon(Icons.edit_sharp,
    color: Colors.white, size: 15.0),
    SizedBox(width: 5),
    Text(
    '手动录入',
    style: TextStyle(
    color: Colors.white,
    fontSize: 13.0,
    fontWeight: FontWeight.w500),
    ),
    ],
    ),
    onPressed: () => _startInput(context))


 */
