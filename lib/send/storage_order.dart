class SendOrder {
  final List<SendOrderDetails> orderDetails;
  final int defaultPostStationId;
  final List<SendStation> stationList;
  final double actuallyPrice;
  SendStation selectedStation;
  String code;

  SendOrder.fromJson(Map<String, dynamic> json)
      : defaultPostStationId = json['defaultPostStationId'],
        actuallyPrice = json['actuallyPrice'],
        orderDetails = (json['orderDetails'] as List<dynamic>)
            .map((e) => SendOrderDetails.fromJson(e))
            .toList(),
        stationList = (json['stationList'] as List<dynamic>)
            .map((e) => SendStation.fromJson(e))
            .toList();
}

class SendStation {
  final int id;
  final String stationName;
  final String tel;

  SendStation({this.id, this.stationName, this.tel});

  SendStation.fromJson(Map<String, dynamic> json)
      : this.stationName = json['stationName'] as String,
        this.tel = json['tel'] as String,
        this.id = json['id'] as int;
}

class SendOrderDetails {
  final String category;
  final String title;
  final int amount;

  SendOrderDetails({this.category, this.title, this.amount});

  SendOrderDetails.fromJson(Map<String, dynamic> json)
      : this.title = json['title'] as String,
        this.category = json['category'] as String,
        this.amount = json['amount'] as int;
}
