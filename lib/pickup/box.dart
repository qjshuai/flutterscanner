class Box {
  final int orderId;
  final String orderCode;
  final String nickname;

  // 6 待入袋 7 待揽收
  final int status;
  final String statusName;
  final String tel;
  final String headImgUrl;
  final String address;
  final List<BoxDetail> details;
  final List<String> pics;

  Box(
      {this.orderId,
      this.orderCode,
      this.nickname,
      this.status,
      this.statusName,
      this.tel,
      this.details,
      this.pics,
      this.headImgUrl,
      this.address});

  String get subTitle {
    return details.map((e) {
      return '${e.category ?? '未知品类'}${e.title ?? '未知价格'}元 ${e.amount ?? -1}件';
    }).join('、');
  }

  factory Box.fromJson(Map<String, dynamic> json) {
    return Box(
      orderId: json['orderId'],
      orderCode: json['orderCode'],
      nickname: json['nickname'],
      status: json['status'],
      statusName: json['statusName'],
      tel: json['tel'],
      headImgUrl: json['headImgUrl'],
      address: json['address'],
      details: (json['details'] as List<dynamic>)
          .map((e) => BoxDetail.fromJson(e))
          .toList(),
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
