class UserWatchedChunk {
  int end;
  int start;

  UserWatchedChunk({this.end, this.start});

  UserWatchedChunk.fromJson(Map<String, dynamic> json) {
    end = json['end'];
    start = json['start'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['end'] = this.end;
    data['start'] = this.start;
    return data;
  }
}
