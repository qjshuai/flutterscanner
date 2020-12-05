class Delivery {
  final int id;
  final String nickname;
  final String createtime;
  final String statusName;
  final String headImgUrl;
  // 1 already  2 ready
  final int type;
  final String orderCode;
  final String tel;
  final List<DeliveryDetail> detailList;

  bool isSelected = false;

  Delivery(
      {this.id,
      this.type,
      this.orderCode,
      this.tel,
      this.nickname,
      this.createtime,
      this.statusName,
      this.headImgUrl,
      this.detailList});

  String get subTitle {
    return detailList.map((e) {
      return '${e.category}${e.title}元 ${e.amount}件';
    }).join('、');
  }

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      nickname: json['nickname'],
      createtime: json['createtime'],
      type: json['type'],
      orderCode: json['orderCode'],
      tel: json['tel'],
      statusName: json['statusName'],
      headImgUrl: json['headImgUrl'],
      detailList: (json['detailList'] as List<dynamic>)
          .map((e) => DeliveryDetail.fromJson(e))
          .toList(),
    );
  }
}

class DeliveryDetail {
  final String title;
  final String category;
  final int amount;

  DeliveryDetail({this.title, this.category, this.amount});

  factory DeliveryDetail.fromJson(Map<String, dynamic> json) {
    return DeliveryDetail(
      title: json['title'],
      category: json['category'],
      amount: json['amount'],
    );
  }
}
