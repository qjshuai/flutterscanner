class StorageOrder {
  final List<StorageOrderDetails> orderDetails;
  final int defaultPostStationId;
  final List<StorageStation> stationList;

  StorageOrder.fromJson(Map<String, dynamic> json)
      : defaultPostStationId = json['defaultPostStationId'] as int,
        orderDetails = (json['orderDetails'] as List<dynamic>)
            .map((e) => StorageOrderDetails.fromJson(e))
            .toList(),
        stationList = (json['stationList'] as List<dynamic>)
            .map((e) => StorageStation.fromJson(e))
            .toList();
}

class StorageStation {
  final int id;
  final String stationName;
  final String tel;

  StorageStation({this.id, this.stationName, this.tel});

  StorageStation.fromJson(Map<String, dynamic> json)
      : this.stationName = json['stationName'] as String,
        this.tel = json['tel'] as String,
        this.id = json['id'] as int;
}

class StorageOrderDetails {
  final String category;
  final String title;
  final int amount;

  StorageOrderDetails({this.category, this.title, this.amount});

  StorageOrderDetails.fromJson(Map<String, dynamic> json)
      : this.title = json['title'] as String,
        this.category = json['category'] as String,
        this.amount = json['amount'] as int;
}
