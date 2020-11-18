import 'package:quiver/strings.dart';

class ReceiptInfo {
  final String shortCode;
  List<ReceiptOrder> orders;

  ReceiptInfo.fromJson(Map<String, dynamic> json)
      : shortCode = json['shortCode'] as String {
    final featuresJson = json['orden'];
    if (featuresJson != null) {
      if (featuresJson is List<dynamic>) {
        orders = featuresJson.map((e) => ReceiptOrder.fromJson(e)).toList();
        return;
      }
    }
    orders = [];
  }
}

class ReceiptOrder {
  final String nickname;
  final String tel;
  final String orderCode;
  List<ReceiptFeature> features;
  List<ReceiptDetail> details;
  List<String> pics;

  String get featuresString {
    if (features.isEmpty) {
      return "无";
    }
    return features.map((e) => e.name ?? '无').join("、");
  }

  String get detailsString {
    if (details.isEmpty) {
      return "无";
    }
    return details
        .map((e) => '${e.category ?? ''} ${e.title}元 ${e.amount}件')
        .join("、");
  }

  ReceiptOrder.fromJson(Map<String, dynamic> json)
      : nickname = json['nickname'] as String,
        tel = json['tel'] as String,
        orderCode = json['orderCode'] as String {
    final picsJson = json['pics'] as List<dynamic> ?? [];
    pics = picsJson.map((e) => e as String).toList();
    final featuresJson = json['features'];
    if (featuresJson != null) {
      if (featuresJson is List<dynamic>) {
        features = featuresJson.map((e) => ReceiptFeature.fromJson(e)).toList();
      } else {
        features = [];
      }
    } else {
      features = [];
    }
    final detailsJson = json['details'];
    if (detailsJson != null) {
      if (detailsJson is List<dynamic>) {
        details = detailsJson.map((e) => ReceiptDetail.fromJson(e)).toList();
      } else {
        details = [];
      }
    } else {
      details = [];
    }
  }
}

class ReceiptFeature {
  final int id;
  final String name;

  ReceiptFeature.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        name = json['name'] as String;
}

class ReceiptDetail {
  final int amount;
  final String title;
  final String category;

  ReceiptDetail.fromJson(Map<String, dynamic> json)
      : amount = json['amount'] as int,
        category = json['category'] as String,
        title = json['title'] as String;
}
