class Delivery {
  final int id;
  final String nickname;
  final String createtime;
  final String statusName;
  final String headImgUrl;
  final List<DeliveryDetail> detailList;

  Delivery(
      {this.id,
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
