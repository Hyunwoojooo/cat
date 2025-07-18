class Food {
  int? id; // DB 고유번호 추가
  String feedingSpotLocation;
  String feedingMethod;
  String cleanlinessRating;
  String shelterCondition;
  String specialNotes;
  String image;
  String discoveryTime;
  String detailLocation;
  String? uniqueId; // 고유 식별자 추가
  String? bowlCountFood; // 그릇수_밥그릇
  String? bowlCountWater; // 그릇수_물그릇
  String? bowlSize; // 그릇 크기
  String? bowlCleanliness; // 그릇 청결 정도
  String? foodRemain; // 사료 잔여 여부
  String? waterRemain; // 물 잔여 여부
  String? foodType; // 사료 종류

  Food({
    this.id,
    required this.feedingSpotLocation,
    required this.feedingMethod,
    required this.cleanlinessRating,
    required this.shelterCondition,
    required this.specialNotes,
    required this.image,
    required this.discoveryTime,
    required this.detailLocation,
    this.uniqueId,
    this.bowlCountFood,
    this.bowlCountWater,
    this.bowlSize,
    this.bowlCleanliness,
    this.foodRemain,
    this.waterRemain,
    this.foodType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feedingSpotLocation': feedingSpotLocation,
      'feedingMethod': feedingMethod,
      'cleanlinessRating': cleanlinessRating,
      'shelterCondition': shelterCondition,
      'specialNotes': specialNotes,
      'image': image,
      'discoveryTime': discoveryTime,
      'detailLocation': detailLocation,
      'uniqueId': uniqueId,
      'bowlCountFood': bowlCountFood,
      'bowlCountWater': bowlCountWater,
      'bowlSize': bowlSize,
      'bowlCleanliness': bowlCleanliness,
      'foodRemain': foodRemain,
      'waterRemain': waterRemain,
      'foodType': foodType,
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      feedingSpotLocation: map['feedingSpotLocation'] ?? '',
      feedingMethod: map['feedingMethod'] ?? '',
      cleanlinessRating: map['cleanlinessRating'] ?? '',
      shelterCondition: map['shelterCondition'] ?? '',
      specialNotes: map['specialNotes'] ?? '',
      image: map['image'] ?? '',
      discoveryTime: map['discoveryTime'] ?? '',
      detailLocation: map['detailLocation'] ?? '',
      uniqueId: map['uniqueId'],
      bowlCountFood: map['bowlCountFood'],
      bowlCountWater: map['bowlCountWater'],
      bowlSize: map['bowlSize'],
      bowlCleanliness: map['bowlCleanliness'],
      foodRemain: map['foodRemain'],
      waterRemain: map['waterRemain'],
      foodType: map['foodType'],
    );
  }

  // copyWith 메서드 추가
  Food copyWith({
    int? id,
    String? feedingSpotLocation,
    String? feedingMethod,
    String? cleanlinessRating,
    String? shelterCondition,
    String? specialNotes,
    String? image,
    String? discoveryTime,
    String? detailLocation,
    String? uniqueId,
    String? bowlCountFood,
    String? bowlCountWater,
    String? bowlSize,
    String? bowlCleanliness,
    String? foodRemain,
    String? waterRemain,
    String? foodType,
  }) {
    return Food(
      id: id ?? this.id,
      feedingSpotLocation: feedingSpotLocation ?? this.feedingSpotLocation,
      feedingMethod: feedingMethod ?? this.feedingMethod,
      cleanlinessRating: cleanlinessRating ?? this.cleanlinessRating,
      shelterCondition: shelterCondition ?? this.shelterCondition,
      specialNotes: specialNotes ?? this.specialNotes,
      image: image ?? this.image,
      discoveryTime: discoveryTime ?? this.discoveryTime,
      detailLocation: detailLocation ?? this.detailLocation,
      uniqueId: uniqueId ?? this.uniqueId,
      bowlCountFood: bowlCountFood ?? this.bowlCountFood,
      bowlCountWater: bowlCountWater ?? this.bowlCountWater,
      bowlSize: bowlSize ?? this.bowlSize,
      bowlCleanliness: bowlCleanliness ?? this.bowlCleanliness,
      foodRemain: foodRemain ?? this.foodRemain,
      waterRemain: waterRemain ?? this.waterRemain,
      foodType: foodType ?? this.foodType,
    );
  }
}
