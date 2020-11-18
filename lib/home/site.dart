class Site {
  final int id;
  final String stationName;
  final int readyReceive;

  Site({this.id, this.stationName, this.readyReceive});

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
        id: json['id'],
        stationName: json['stationName'],
        readyReceive: json['readyReceive']);
  }
}
