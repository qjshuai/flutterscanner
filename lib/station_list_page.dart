import 'package:cached_network_image/cached_network_image.dart';
import 'package:environment/request_state.dart';
import 'package:environment/service_center.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scanner/custom_color.dart';
import 'package:scanner/home/site.dart';

import 'delivery.dart';

class DeliveryListPage extends StatefulWidget {
  final Site site;

  DeliveryListPage(this.site);

  @override
  _DeliveryListPageState createState() => _DeliveryListPageState();
}

class _DeliveryListPageState extends State<DeliveryListPage> {
  // RequestState _requestState;
  /// 驿站列表内容
  // Widget _buildContent(BuildContext context) {
  //   if (_requestState is RequestStateRequesting) {
  //     return Center(child: CircularProgressIndicator());
  //   } else if (_requestState is RequestStateFailure) {
  //     return Center(
  //         child: SizedBox(
  //           child: SizedBox(
  //             width: 120,
  //             height: 50,
  //             child: FlatButton(
  //               child: Text(
  //                 '重试',
  //                 style: Theme.of(context).primaryTextTheme.subtitle1,
  //               ),
  //               onPressed: () => _fetchSiteList(),
  //             ),
  //           ),
  //         ));
  //   } else {
  //     return _buildStationList(context);
  //   }
  // }

  RefreshController _refreshController =
      RefreshController(initialRefresh: true);
  List<Delivery> _deliveries = [];

  int _page = 1;
  int _total = 0;

  int get _limit => 20;

  Future<Map<String, dynamic>> _fetchSiteList() async {
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    final response = await http.get('/roshine/poststation/selectReadyReceive',
        queryParameters: {'id': widget.site.id});
    final sites = ((response.data['data']) as List<dynamic>)
        .map((e) => Delivery.fromJson(e))
        .toList();
    final total = response.data['total'] as int;
    final pageNum = response.data['pageNum'] as int;
    return {'data': sites, 'total': total, 'pageNum': pageNum};
  }

  void _onRefresh() async {
    _page = 1;
    try {
      final result = await _fetchSiteList();
      _total = result['total'];
      final deliveries = result['data'];
      if (deliveries.isEmpty) {
        _refreshController.refreshCompleted();
      } else {
        _refreshController.refreshCompleted();
        setState(() {
          _deliveries = deliveries;
        });
      }
    } catch (e) {
      print(e);
      // Fluttertoast.cancel();
      // Fluttertoast.showToast(msg: e.toString());
      _page -= 1;
      _refreshController.refreshFailed();
    }
  }

  void _onLoading() async {
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
      print(e);
      _page -= 1;
      _refreshController.loadFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('${widget.site.stationName}-待取件'),
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
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: _buildStationList(context),
          ),
        ),
      ),
    );
  }

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
            itemExtent: 90.0,
            itemCount: _deliveries.length,
            itemBuilder: (context, index) {
              final delivery = _deliveries[index];
              return Column(
                children: [
                  Expanded(
                      child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: CachedNetworkImage(
                              imageUrl: delivery.headImgUrl,
                              width: 50.0,
                              height: 50.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 10.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(delivery.nickname,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText1
                                      .copyWith(
                                          color: CustomColor.darkTextColor,
                                          fontWeight: FontWeight.w500)),
                              Text(
                                delivery.subTitle,
                                style: TextStyle(
                                    color: Color(0xFF8C9C9D), fontSize: 11),
                              ),
                              Text(
                                delivery.createtime,
                                style: TextStyle(
                                    color: Color(0xFFB8C8C5), fontSize: 10),
                              ),
                            ],
                          ),
                          Spacer(),
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
                                child: Center(
                                  child: Text(
                                    delivery.statusName,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                          // Text(
                          //   '驿站驿站驿站',
                          //   style: Theme.of(context)
                          //       .textTheme
                          //       .subtitle1
                          //       .copyWith(color: Color(0xFF263336)),
                          // ),
                        ],
                      ),
                    ),
                  )),
                  SizedBox(height: 10.0)
                ],
              );
            }));
  }
}
