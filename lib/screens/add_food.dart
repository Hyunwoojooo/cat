import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cat_project/main.dart';
import '../database/food_db.dart';
import '../models/food.dart';
import 'package:path_provider/path_provider.dart';
import 'package:exif/exif.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';

class AddFood extends StatefulWidget {
  const AddFood({super.key});

  @override
  State<AddFood> createState() => _AddFoodState();
}

class _AddFoodState extends State<AddFood> {
  final picker = ImagePicker();
  String? savedImagePath;
  String specialNotes = '';
  String feedingSpotLocation = '';
  String? imageDateTime;
  String? detailLocation; // 상세 주소 변수 추가

  // 드롭다운 선택값
  String? selectedFeedingMethod;
  String? selectedCleanlinessRating;
  String? selectedShelterCondition;
  String? bowlCountFood;
  String? bowlCountWater;
  String? selectedBowlSize;
  String? selectedBowlCleanliness;
  String? selectedFoodRemain;
  String? selectedWaterRemain;
  String? selectedFoodType;

  final List<String> feedingMethodItems = [
    "선택",
    "1. 자유급식",
    "2. 시간제급식",
    "3. 수동급식",
  ];

  final List<String> cleanlinessRatingItems = [
    "선택",
    "1. 매우 깨끗함",
    "2. 깨끗함",
    "3. 보통",
    "4. 더러움",
    "5. 매우 더러움",
  ];

  final List<String> shelterConditionItems = [
    "선택",
    "1. 매우 좋음",
    "2. 좋음",
    "3. 보통",
    "4. 나쁨",
    "5. 매우 나쁨",
  ];

  final List<String> bowlSizeItems = [
    "선택",
    "1. 작음",
    "2. 보통",
    "3. 큼",
  ];

  final List<String> bowlCleanlinessItems = [
    "선택",
    "1. 매우 깨끗함",
    "2. 깨끗함",
    "3. 보통",
    "4. 더러움",
    "5. 매우 더러움",
  ];

  final List<String> foodRemainItems = [
    "선택",
    "1. 없음",
    "2. 적음",
    "3. 보통",
    "4. 많음",
    "5. 매우 많음",
  ];

  final List<String> waterRemainItems = [
    "선택",
    "1. 없음",
    "2. 적음",
    "3. 보통",
    "4. 많음",
    "5. 매우 많음",
  ];

  final List<String> foodTypeItems = [
    "선택",
    "1. 건사료",
    "2. 습식사료",
    "3. 생고기",
    "4. 생선",
    "5. 기타",
  ];

  // Kakao Maps API 키를 상수로 정의
  static const String KAKAO_API_KEY =
      '4faeb42201cf02a0d3555f161c3879ad'; // TODO: 실제 API 키로 교체 필요

  // 권한 요청 함수
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      print('=== 권한 확인 시작 ===');

      try {
        // 위치 권한만 확인 (이미지 읽기는 권한이 필요하지 않음)
        PermissionStatus locationStatus = await Permission.location.status;
        print('현재 위치 권한 상태: $locationStatus');

        // 위치 권한이 이미 허용되어 있는지 확인
        if (locationStatus.isGranted) {
          print('위치 권한이 이미 허용되어 있습니다.');
          return true;
        }

        // 위치 권한만 요청
        print('위치 권한 요청 중...');
        PermissionStatus result = await Permission.location.request();
        print('위치 권한 요청 후 상태: $result');

        if (result.isGranted) {
          print('위치 권한이 허용되었습니다.');
          return true;
        } else {
          print('위치 권한이 거부되었습니다.');
          // 권한이 거부된 경우 사용자에게 설명
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('위치 권한 필요'),
                  content: Text(
                      '이미지의 GPS 위치 정보를 읽기 위해서는 위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('취소'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        openAppSettings();
                      },
                      child: Text('설정으로 이동'),
                    ),
                  ],
                );
              },
            );
          }
          return false;
        }
      } catch (e) {
        print('권한 요청 중 오류 발생: $e');
        return false;
      }
    }
    return true;
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 14, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required List<String> items,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade600,
          ),
          style: TextStyle(fontSize: 15, color: Colors.black87),
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem(value: item, child: Text(item)),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 14),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        savedImagePath != null && File(savedImagePath!).existsSync()
            ? SizedBox(
                width: double.infinity,
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(savedImagePath!), fit: BoxFit.cover),
                ),
              )
            : SizedBox(
                height: 220,
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.grey.shade200,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "이미지를 선택해주세요",
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  // 시간 선택 관련 변수
  TimeOfDay? selectedTime;
  String get formattedTime {
    if (imageDateTime == null) {
      return '발견 시간을 선택해주세요';
    }
    return imageDateTime!;
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();
    DateTime initialDate = now;
    if (imageDateTime != null) {
      // "2025:05:30 15:03:09" → DateTime 파싱
      final reg = RegExp(
        r"^(\\d{4}):(\\d{2}):(\\d{2}) (\\d{2}):(\\d{2}):(\\d{2})\$",
      );
      final match = reg.firstMatch(imageDateTime!);
      if (match != null) {
        initialDate = DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
          int.parse(match.group(4)!),
          int.parse(match.group(5)!),
          int.parse(match.group(6)!),
        );
      }
    }

    // 날짜 선택
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    // 시간 선택
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialDate.hour,
        minute: initialDate.minute,
      ),
    );
    if (pickedTime == null) return;

    setState(() {
      imageDateTime =
          "${pickedDate.year}:${pickedDate.month.toString().padLeft(2, '0')}:${pickedDate.day.toString().padLeft(2, '0')} "
          "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00";
    });
  }

  Future<String?> _saveImageToAppDirectory(XFile imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${appDir.path}/$fileName';
      final File newImage = await File(imageFile.path).copy(filePath);
      return newImage.path;
    } catch (e) {
      print('이미지 저장 오류: $e');
      return null;
    }
  }

  // 위도/경도를 도로명 주소로 변환하는 함수
  Future<String?> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat',
        ),
        headers: {
          'Authorization': 'KakaoAK $KAKAO_API_KEY',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['documents'] != null && data['documents'].isNotEmpty) {
          final doc = data['documents'][0];
          final road = doc['road_address'];
          final jibun = doc['address'];
          if (road != null && road['address_name'] != null) {
            return road['address_name'];
          } else if (jibun != null && jibun['address_name'] != null) {
            return jibun['address_name'];
          }
        }
      }
      return null;
    } catch (e) {
      print('주소 변환 중 오류 발생: $e');
      return null;
    }
  }

  Future<void> _showImagePicker() async {
    try {
      // 안드로이드에서 권한 요청
      if (Platform.isAndroid) {
        bool hasPermissions = await _requestPermissions();
        if (!hasPermissions) {
          return; // 권한이 없으면 이미지 선택을 중단
        }
      }

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        final String? savedPath = await _saveImageToAppDirectory(pickedFile);
        if (savedPath != null) {
          // EXIF 데이터 먼저 읽고, 그 결과를 setState에서 한 번에 반영
          final exifResult = await _readExifDataForState(savedPath);
          setState(() {
            savedImagePath = savedPath;
            imageDateTime = formatDateTimeKor(exifResult['imageDateTime']);
            feedingSpotLocation = exifResult['locationName'] ?? '';
          });
        }
      } else {
        print('이미지가 선택되지 않았습니다.');
      }
    } catch (e) {
      print('이미지 선택 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지를 선택하는 중 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // EXIF 데이터만 읽고, setState는 하지 않는 함수
  Future<Map<String, dynamic>> _readExifDataForState(String imagePath) async {
    String? newImageDateTime;
    String? newLocationName;
    double? newLatitude;
    double? newLongitude;
    try {
      final bytes = await File(imagePath).readAsBytes();
      final exifData = await readExifFromBytes(bytes);

      print('=== EXIF 데이터 읽기 시작 ===');
      print('이미지 경로: $imagePath');
      print('EXIF 데이터 키들: ${exifData.keys.toList()}');
      print('플랫폼: ${Platform.operatingSystem}');

      if (exifData.isEmpty) {
        print('EXIF 데이터가 없습니다.');
        return {
          'imageDateTime': null,
          'locationName': null,
          'latitude': null,
          'longitude': null,
        };
      }

      // 날짜/시간 정보 읽기 (여러 형식 시도)
      if (exifData.containsKey('EXIF DateTimeOriginal')) {
        final dateTimeStr = exifData['EXIF DateTimeOriginal']?.printable;
        print('EXIF DateTimeOriginal: $dateTimeStr');
        newImageDateTime = dateTimeStr;
      } else if (exifData.containsKey('Image DateTime')) {
        final dateTimeStr = exifData['Image DateTime']?.printable;
        print('Image DateTime: $dateTimeStr');
        newImageDateTime = dateTimeStr;
      } else if (exifData.containsKey('EXIF DateTime')) {
        final dateTimeStr = exifData['EXIF DateTime']?.printable;
        print('EXIF DateTime: $dateTimeStr');
        newImageDateTime = dateTimeStr;
      }

      // GPS 정보 읽기 (더 안전한 방식)
      bool hasGpsData = false;

      // GPS 위도/경도 확인
      if (exifData.containsKey('GPS GPSLatitude') &&
          exifData.containsKey('GPS GPSLongitude')) {
        hasGpsData = true;
        print('GPS 데이터 발견');

        try {
          final latValue = exifData['GPS GPSLatitude']!;
          final lonValue = exifData['GPS GPSLongitude']!;
          final latRef = exifData['GPS GPSLatitudeRef']?.printable;
          final lonRef = exifData['GPS GPSLongitudeRef']?.printable;

          print('GPS 위도 값: $latValue');
          print('GPS 경도 값: $lonValue');
          print('GPS 위도 참조: $latRef');
          print('GPS 경도 참조: $lonRef');

          // 값이 Ratio 리스트인지 확인
          if (latValue.values.length > 0 && lonValue.values.length > 0) {
            newLatitude = _convertGpsToDecimal(
              latValue.values.toList().cast<Ratio>(),
            );
            newLongitude = _convertGpsToDecimal(
              lonValue.values.toList().cast<Ratio>(),
            );

            print('변환된 위도: $newLatitude');
            print('변환된 경도: $newLongitude');

            // 남반구/서반구 처리
            if (latRef == 'S') newLatitude = -newLatitude;
            if (lonRef == 'W') newLongitude = -newLongitude;

            print('최종 위도: $newLatitude');
            print('최종 경도: $newLongitude');

            // 위도/경도를 도로명 주소로 변환
            final address = await _getAddressFromCoordinates(
              newLatitude,
              newLongitude,
            );
            newLocationName = address ??
                '위도: ${newLatitude.toStringAsFixed(4)}, 경도: ${newLongitude.toStringAsFixed(4)}';
            print('변환된 주소: $newLocationName');
          } else {
            print('GPS 값이 비어있습니다.');
          }
        } catch (e) {
          print('GPS 데이터 변환 오류: $e');
        }
      } else {
        print('GPS 데이터가 없습니다.');
        // GPS 관련 키들 출력
        exifData.keys.where((key) => key.contains('GPS')).forEach((key) {
          print('GPS 관련 키: $key = ${exifData[key]?.printable}');
        });
      }

      print('=== EXIF 데이터 읽기 완료 ===');
      print('날짜/시간: $newImageDateTime');
      print('위치: $newLocationName');
      print('위도: $newLatitude');
      print('경도: $newLongitude');

      return {
        'imageDateTime': newImageDateTime,
        'locationName': newLocationName,
        'latitude': newLatitude,
        'longitude': newLongitude,
      };
    } catch (e) {
      print('EXIF 데이터 읽기 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return {
        'imageDateTime': null,
        'locationName': null,
        'latitude': null,
        'longitude': null,
      };
    }
  }

  double _convertGpsToDecimal(List<Ratio> ratios) {
    if (ratios.length != 3) return 0.0;
    double degrees = ratios[0].toDouble();
    double minutes = ratios[1].toDouble();
    double seconds = ratios[2].toDouble();
    return degrees + (minutes / 60.0) + (seconds / 3600.0);
  }

  bool get isFormValid {
    return savedImagePath != null &&
        selectedFeedingMethod != null &&
        selectedFeedingMethod != "선택" &&
        selectedCleanlinessRating != null &&
        selectedCleanlinessRating != "선택" &&
        selectedShelterCondition != null &&
        selectedShelterCondition != "선택" &&
        bowlCountFood != null &&
        bowlCountFood!.isNotEmpty &&
        bowlCountWater != null &&
        bowlCountWater!.isNotEmpty &&
        selectedBowlSize != null &&
        selectedBowlSize != "선택" &&
        selectedBowlCleanliness != null &&
        selectedBowlCleanliness != "선택" &&
        selectedFoodRemain != null &&
        selectedFoodRemain != "선택" &&
        selectedWaterRemain != null &&
        selectedWaterRemain != "선택" &&
        selectedFoodType != null &&
        selectedFoodType != "선택";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("급식 정보 추가", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 선택
                GestureDetector(
                  onTap: _showImagePicker,
                  child: _buildPhotoArea(),
                ),
                _buildLabel("발견 시간"),
                _buildTimeInfoBox(),
                _buildLabel("급식 장소"),
                _buildInfoBox(
                  icon: Icons.location_on,
                  text: feedingSpotLocation.isNotEmpty
                      ? feedingSpotLocation
                      : '위치 정보 없음',
                ),
                _buildLabel("상세 주소"),
                TextField(
                  decoration: InputDecoration(
                    hintText: '상세 주소를 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: (v) => setState(() => detailLocation = v),
                ),
                _buildLabel("급여 방식"),
                _buildDropdown(
                  items: feedingMethodItems,
                  value: selectedFeedingMethod ?? feedingMethodItems[0],
                  onChanged: (v) => setState(() => selectedFeedingMethod = v),
                ),
                _buildLabel("청결도 평가"),
                _buildDropdown(
                  items: cleanlinessRatingItems,
                  value: selectedCleanlinessRating ?? cleanlinessRatingItems[0],
                  onChanged: (v) =>
                      setState(() => selectedCleanlinessRating = v),
                ),
                _buildLabel("쉼터 상태"),
                _buildDropdown(
                  items: shelterConditionItems,
                  value: selectedShelterCondition ?? shelterConditionItems[0],
                  onChanged: (v) =>
                      setState(() => selectedShelterCondition = v),
                ),
                _buildLabel("밥그릇 수"),
                TextField(
                  decoration: InputDecoration(
                    hintText: '밥그릇 수를 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => bowlCountFood = v),
                ),
                _buildLabel("물그릇 수"),
                TextField(
                  decoration: InputDecoration(
                    hintText: '물그릇 수를 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => bowlCountWater = v),
                ),
                _buildLabel("그릇 크기"),
                _buildDropdown(
                  items: bowlSizeItems,
                  value: selectedBowlSize ?? bowlSizeItems[0],
                  onChanged: (v) => setState(() => selectedBowlSize = v),
                ),
                _buildLabel("그릇 청결 정도"),
                _buildDropdown(
                  items: bowlCleanlinessItems,
                  value: selectedBowlCleanliness ?? bowlCleanlinessItems[0],
                  onChanged: (v) => setState(() => selectedBowlCleanliness = v),
                ),
                _buildLabel("사료 잔여 여부"),
                _buildDropdown(
                  items: foodRemainItems,
                  value: selectedFoodRemain ?? foodRemainItems[0],
                  onChanged: (v) => setState(() => selectedFoodRemain = v),
                ),
                _buildLabel("물 잔여 여부"),
                _buildDropdown(
                  items: waterRemainItems,
                  value: selectedWaterRemain ?? waterRemainItems[0],
                  onChanged: (v) => setState(() => selectedWaterRemain = v),
                ),
                _buildLabel("사료 종류"),
                _buildDropdown(
                  items: foodTypeItems,
                  value: selectedFoodType ?? foodTypeItems[0],
                  onChanged: (v) => setState(() => selectedFoodType = v),
                ),
                _buildLabel("특이사항"),
                TextField(
                  decoration: InputDecoration(
                    hintText: '특이사항을 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  maxLines: 2,
                  onChanged: (v) => setState(() => specialNotes = v),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isFormValid ? Colors.teal : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      minimumSize: Size(340, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isFormValid ? _onCompletePressed : null,
                    child: Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onCompletePressed() async {
    if (savedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지를 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (selectedFeedingMethod == null ||
        selectedFeedingMethod == "선택" ||
        selectedCleanlinessRating == null ||
        selectedCleanlinessRating == "선택" ||
        selectedShelterCondition == null ||
        selectedShelterCondition == "선택") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 필수 항목을 선택해주세요.')));
      return;
    }

    try {
      print('저장할 급식 정보:');
      print('feedingSpotLocation: $feedingSpotLocation');
      print('discoveryTime: ${imageDateTime ?? ""}');
      print('detailLocation: ${detailLocation ?? "-"}');
      print('feedingMethod: $selectedFeedingMethod');
      print('cleanlinessRating: $selectedCleanlinessRating');
      print('shelterCondition: $selectedShelterCondition');
      print('bowlCountFood: $bowlCountFood');
      print('bowlCountWater: $bowlCountWater');
      print('bowlSize: $selectedBowlSize');
      print('bowlCleanliness: $selectedBowlCleanliness');
      print('foodRemain: $selectedFoodRemain');
      print('waterRemain: $selectedWaterRemain');
      print('foodType: $selectedFoodType');
      print('specialNotes: ${specialNotes ?? "-"}');
      print('image: $savedImagePath');

      final food = Food(
        feedingSpotLocation:
            feedingSpotLocation.isNotEmpty ? feedingSpotLocation : '위치 정보 없음',
        feedingMethod: selectedFeedingMethod!,
        cleanlinessRating: selectedCleanlinessRating!,
        shelterCondition: selectedShelterCondition!,
        specialNotes: specialNotes.isNotEmpty ? specialNotes : '-',
        image: savedImagePath!,
        discoveryTime: imageDateTime != null && imageDateTime!.isNotEmpty
            ? imageDateTime! // 이미 한글 포맷으로 변환되어 있으므로 그대로 사용
            : '시간 정보 없음',
        detailLocation:
            detailLocation?.isNotEmpty == true ? detailLocation! : '-',
        bowlCountFood: bowlCountFood?.isNotEmpty == true ? bowlCountFood : null,
        bowlCountWater:
            bowlCountWater?.isNotEmpty == true ? bowlCountWater : null,
        bowlSize:
            selectedBowlSize?.isNotEmpty == true && selectedBowlSize != "선택"
                ? selectedBowlSize
                : null,
        bowlCleanliness: selectedBowlCleanliness?.isNotEmpty == true &&
                selectedBowlCleanliness != "선택"
            ? selectedBowlCleanliness
            : null,
        foodRemain:
            selectedFoodRemain?.isNotEmpty == true && selectedFoodRemain != "선택"
                ? selectedFoodRemain
                : null,
        waterRemain: selectedWaterRemain?.isNotEmpty == true &&
                selectedWaterRemain != "선택"
            ? selectedWaterRemain
            : null,
        foodType:
            selectedFoodType?.isNotEmpty == true && selectedFoodType != "선택"
                ? selectedFoodType
                : null,
      );

      final result = await FoodDatabase.instance.insertFood(food);
      print('데이터베이스 저장 결과: $result');

      // 저장 후 즉시 확인
      final savedFoods = await FoodDatabase.instance.getAllFoods();
      print('저장 후 전체 급식 정보 수: ${savedFoods.length}');
      for (var savedFood in savedFoods) {
        print('저장된 급식 정보: ${savedFood.feedingSpotLocation}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('급식 정보가 저장되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(food);
      }
    } catch (e, stackTrace) {
      print('데이터 저장 중 오류 발생: $e');
      print('스택 트레이스: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 저장 중 오류가 발생했습니다: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 주요 발견 시간 위젯
  Widget _buildTimeInfoBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildInfoBox(
                icon: Icons.access_time,
                text: formattedTime,
              ),
            ),
            TextButton(
              onPressed: () => _selectDateTime(context),
              child: Text(
                imageDateTime == null ? '선택' : '수정',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String formatDateTimeKor(String input) {
  try {
    final reg = RegExp(r"^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})$");
    final match = reg.firstMatch(input);
    if (match == null) return input;
    return "${match.group(1)}년${match.group(2)}월${match.group(3)}일 "
        "${match.group(4)}시${match.group(5)}분${match.group(6)}초";
  } catch (_) {
    return input;
  }
}
