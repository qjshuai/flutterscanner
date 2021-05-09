import 'package:scanner/receipt/receipt_info.dart';

class Box {
  final int orderId;
  final String orderCode;
  final String serviceCode;
  final String nickname;

  // 6 待入袋 7 待揽收
  final int status;
  final String latitude;
  final String longitude;
  final String statusName;
  final String tel;
  final String headImgUrl;
  final String address;
  final List<BoxDetail> details;
  final List<String> pics;
  final int parcelNum;

  List<ReceiptFeature> features;

  bool needRefresh = false;

  String get featuresString {
    if (features.isEmpty) {
      return "无";
    }
    return features.map((e) => e.name ?? '无').join("、");
  }

  Box(
      {this.parcelNum,
      this.orderId,
      this.orderCode,
      this.nickname,
      this.status,
      this.statusName,
      this.tel,
      this.details,
      this.pics,
      this.headImgUrl,
      this.latitude,
      this.longitude,
      this.address,
      this.serviceCode,
      this.features});

  String get subTitle {
    return (details?.map((e) {
              return '${e.category ?? '未知品类'}${e.title ?? '未知价格'}元 ${e.amount ?? -1}件';
            })?.toList() ??
            [])
        .join('、');
  }

  factory Box.fromJson(Map<String, dynamic> json) {
    print(json['tel']);
    return Box(
      orderId: json['orderId'],
      parcelNum: json['parcelNum'],
      orderCode: json['orderCode'],
      nickname: json['nickname'],
      status: json['status'],
      tel: json['tel'],
      statusName: json['statusName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      pics: (json['pics'] as List<dynamic>)
          ?.map((e) => e as String)
          ?.toList() ??
          [],
      serviceCode: json['serviceCode'],
      headImgUrl: json['headImgUrl'],
      address: json['address'],
      features: (json['features'] as List<dynamic>)
              ?.map((e) => ReceiptFeature.fromJson(e))
              ?.toList() ??
          [],
      details: (json['details'] as List<dynamic>)
              ?.map((e) => BoxDetail.fromJson(e))
              ?.toList() ??
          [],
      // pics: json['pics'],
    );
  }
}

class BoxDetail {
  final String title;
  final String category;
  final int amount;

  BoxDetail({this.title, this.category, this.amount});

  factory BoxDetail.fromJson(Map<String, dynamic> json) {
    return BoxDetail(
      title: json['title'],
      category: json['category'],
      amount: json['amount'],
    );
  }
}
