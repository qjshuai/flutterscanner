import 'package:quiver/strings.dart';

class Group {
  final String shortCode;
  List<Order> orden;

  Group.fromJson(Map<String, dynamic> json)
      : shortCode = json['shortCode'] as String {
    final featuresJson = json['orden'];
    if (featuresJson != null) {
      if (featuresJson is List<dynamic>) {
        orden = featuresJson.map((e) => Order.fromJson(e)).toList();
        return;
      }
    }
    orden = [];
  }
}

class Order {
  final String nickname;
  final String tel;
  final String orderCode;
  List<Feature> features;
  List<Detail> details;
  List<String> pics;

  String get featuresString {
    if (features.isEmpty) {
      return "无";
    }
    return features.map((e) => e.name ?? '无').join("、");//.where((element) => isNotEmpty(element.name))
  }
  String get detailsString {
    if (details.isEmpty) {
      return "无";
    }
    return details.map((e) => '${e.category ?? ''} ${e.title}元 ${e.amount}件').join("、");
  }

  Order.fromJson(Map<String, dynamic> json)
      : nickname = json['nickname'] as String,
        tel = json['tel'] as String,
        orderCode = json['orderCode'] as String {
    final picsJson = json['pics'] as List<dynamic> ?? [];
    pics = picsJson.map((e) => e as String).toList();
    final featuresJson = json['features'];
    if (featuresJson != null) {
      if (featuresJson is List<dynamic>) {
        features = featuresJson.map((e) => Feature.fromJson(e)).toList();
      } else {
        features = [];
      }
    } else {
      features = [];
    }
    final detailsJson = json['details'];
    if (detailsJson != null) {
      if (detailsJson is List<dynamic>) {
        details = detailsJson.map((e) => Detail.fromJson(e)).toList();
      } else {
        details = [];
      }
    } else {
      details = [];
    }
  }
}

class Feature {
  final int id;
  final String name;

  Feature.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        name = json['name'] as String;
}

class Detail {
  final int amount;
  final String title;
  final String category;

  Detail.fromJson(Map<String, dynamic> json)
      : amount = json['amount'] as int,
        category = json['category'] as String,
        title = json['title'] as String;
}
