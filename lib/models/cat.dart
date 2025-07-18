class Cat {
  String catId;
  String keyDiscoveryTime;
  String location;
  String detailLocation;
  String furColor;
  String age;
  bool isNeutered;
  String specialNotes;
  String image;
  String pattern;
  String eyeColor;
  int isDuplicate;
  String? uniqueId; // 고유 식별자 추가

  Cat({
    required this.catId,
    required this.keyDiscoveryTime,
    required this.location,
    required this.detailLocation,
    required this.furColor,
    required this.age,
    required this.isNeutered,
    required this.specialNotes,
    required this.image,
    required this.pattern,
    required this.eyeColor,
    required this.isDuplicate,
    this.uniqueId,
  });

  Map<String, dynamic> toMap() {
    return {
      'catId': catId,
      'keyDiscoveryTime': keyDiscoveryTime,
      'location': location,
      'detailLocation': detailLocation,
      'furColor': furColor,
      'age': age,
      'isNeutered': isNeutered,
      'specialNotes': specialNotes,
      'image': image,
      'pattern': pattern,
      'eyeColor': eyeColor,
      'isDuplicate': isDuplicate,
      'uniqueId': uniqueId,
    };
  }

  factory Cat.fromMap(Map<String, dynamic> map) {
    return Cat(
      catId: map['catId'],
      keyDiscoveryTime: map['keyDiscoveryTime'],
      location: map['location'],
      detailLocation: map['detailLocation'],
      furColor: map['furColor'],
      age: map['age'],
      isNeutered: map['isNeutered'],
      specialNotes: map['specialNotes'],
      image: map['image'],
      pattern: map['pattern'],
      eyeColor: map['eyeColor'],
      isDuplicate: map['isDuplicate'],
      uniqueId: map['uniqueId'],
    );
  }

  // copyWith 메서드 추가
  Cat copyWith({
    String? catId,
    String? keyDiscoveryTime,
    String? location,
    String? detailLocation,
    String? furColor,
    String? age,
    bool? isNeutered,
    String? specialNotes,
    String? image,
    String? pattern,
    String? eyeColor,
    int? isDuplicate,
    String? uniqueId,
  }) {
    return Cat(
      catId: catId ?? this.catId,
      keyDiscoveryTime: keyDiscoveryTime ?? this.keyDiscoveryTime,
      location: location ?? this.location,
      detailLocation: detailLocation ?? this.detailLocation,
      furColor: furColor ?? this.furColor,
      age: age ?? this.age,
      isNeutered: isNeutered ?? this.isNeutered,
      specialNotes: specialNotes ?? this.specialNotes,
      image: image ?? this.image,
      pattern: pattern ?? this.pattern,
      eyeColor: eyeColor ?? this.eyeColor,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      uniqueId: uniqueId ?? this.uniqueId,
    );
  }
}
