class StorageOrder {
  final List<OrderDetails> orderDetails;
  final int defaultPostStationId;
  final List<Station> stationList;

  StorageOrder.fromJson(Map<String, dynamic> json)
      : defaultPostStationId = json['defaultPostStationId'] as int,
        orderDetails = (json['orderDetails'] as List<dynamic>)
            .map((e) => OrderDetails.fromJson(e))
            .toList(),
        stationList = (json['stationList'] as List<dynamic>)
            .map((e) => Station.fromJson(e))
            .toList();
}

class Station {
  final int id;
  final String stationName;
  final String tel;

  Station({this.id, this.stationName, this.tel});

  Station.fromJson(Map<String, dynamic> json)
      : this.stationName = json['stationName'] as String,
        this.tel = json['tel'] as String,
        this.id = json['id'] as int;
}

class OrderDetails {
  final String category;
  final String title;
  final int amount;

  OrderDetails({this.category, this.title, this.amount});

  OrderDetails.fromJson(Map<String, dynamic> json)
      : this.title = json['title'] as String,
        this.category = json['category'] as String,
        this.amount = json['amount'] as int;
}
