import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cat_project/main.dart';
import '../components/colors.dart';
import '../database/food_db.dart';
import '../models/food.dart';
import 'package:exif/exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import 'package:cat_project/components/colors.dart';

class InfoFood extends StatefulWidget {
  final Food food;
  const InfoFood({required this.food, super.key});

  @override
  State<InfoFood> createState() => _InfoFoodState();
}

class _InfoFoodState extends State<InfoFood> {
  final picker = ImagePicker();
  final TextEditingController _specialNotesController = TextEditingController();
  final TextEditingController _detailLocationController =
      TextEditingController();
  String? savedImagePath;
  String specialNotes = '';
  String? imageDateTime;
  String? feedingSpotLocation;
  String? detailLocation;
  String? feedingMethod;
  String? cleanlinessRating;
  String? shelterCondition;
  String? bowlCountFood;
  String? bowlCountWater;
  String? bowlSize;
  String? bowlCleanliness;
  String? foodRemain;
  String? waterRemain;
  String? foodType;

  // 기존 데이터 저장
  String? originalImagePath;
  String? originalImageDateTime;
  String? originalFeedingSpotLocation;
  String? originalDetailLocation;
  String? originalFeedingMethod;
  String? originalCleanlinessRating;
  String? originalShelterCondition;
  String? originalSpecialNotes;
  String? originalBowlCountFood;
  String? originalBowlCountWater;
  String? originalBowlSize;
  String? originalBowlCleanliness;
  String? originalFoodRemain;
  String? originalWaterRemain;
  String? originalFoodType;

  // 드롭다운 항목 리스트 (add_food.dart와 동일하게 맞춰주세요)
  final List<String> feedingMethodItems = [
    "선택",
    "밥 그릇만",
    "바닥(그릇 없음)",
    "자동 급여기"
  ];
  final List<String> cleanlinessRatingItems = [
    "선택",
    "1. 전혀 위생적이지 않음",
    "2. 위생적이지 않음",
    "3. 보통",
    "4. 위생적임",
    "5. 매우 위생적임",
  ];
  final List<String> shelterConditionItems = [
    "선택",
    "1. 전혀 노출되지 않음",
    "2. 노출되지 않음",
    "3. 보통",
    "4. 노출됨",
    "5. 매우 노출됨"
  ];
  final List<String> bowlSizeItems = [
    "선택",
    "1. 250ml(접시, 햇반)",
    "2. 500ml(국그릇)",
    "3. 1L(냄비 그릇)",
    "4. 2L(탕요기) 이상"
  ];
  final List<String> bowlCleanlinessItems = [
    "선택",
    "1. 매우 더러움",
    "2. 더러움",
    "3. 보통",
    "4. 청결",
    "5. 매우 청결"
  ];
  final List<String> foodRemainItems = ["선택", "1. 사료 있음", "2. 사료 없음"];
  final List<String> waterRemainItems = ["선택", "1. 물 있음", "2. 물 없음"];
  final List<String> foodTypeItems = [
    "선택",
    "1. 건사료",
    "2. 동물용 습식캔",
    "3. 사람 음식물",
    "4. 확인 불가"
  ];

  // Kakao Maps API 키를 상수로 정의
  static const String KAKAO_API_KEY =
      '4faeb42201cf02a0d3555f161c3879ad'; // TODO: 실제 API 키로 교체 필요

  // 권한 요청 함수
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      print('=== 권한 확인 시작 ===');

      // 위치 권한만 확인 (이미지 읽기는 권한이 필요하지 않음)
      PermissionStatus locationStatus = await Permission.location.status;
      print('현재 위치 권한 상태: $locationStatus');

      // 위치 권한이 이미 허용되어 있는지 확인
      if (locationStatus.isGranted) {
        print('위치 권한이 이미 허용되어 있습니다.');
        return true;
      }

      // 위치 권한만 요청
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
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadFoodData();
  }

  @override
  void dispose() {
    _specialNotesController.dispose();
    _detailLocationController.dispose();
    super.dispose();
  }

  void _loadFoodData() {
    setState(() {
      savedImagePath = widget.food.image;
      imageDateTime = widget.food.discoveryTime;
      feedingSpotLocation = widget.food.feedingSpotLocation;
      detailLocation = widget.food.detailLocation;
      _detailLocationController.text = widget.food.detailLocation ?? '';
      feedingMethod = widget.food.feedingMethod;
      cleanlinessRating = widget.food.cleanlinessRating;
      shelterCondition = widget.food.shelterCondition;
      bowlCountFood = widget.food.bowlCountFood;
      bowlCountWater = widget.food.bowlCountWater;
      bowlSize = widget.food.bowlSize;
      bowlCleanliness = widget.food.bowlCleanliness;
      foodRemain = widget.food.foodRemain;
      waterRemain = widget.food.waterRemain;
      foodType = widget.food.foodType;
      specialNotes = widget.food.specialNotes;
      _specialNotesController.text = widget.food.specialNotes;
      // 기존 값 저장
      originalImagePath = widget.food.image;
      originalImageDateTime = widget.food.discoveryTime;
      originalFeedingSpotLocation = widget.food.feedingSpotLocation;
      originalDetailLocation = widget.food.detailLocation;
      originalFeedingMethod = widget.food.feedingMethod;
      originalCleanlinessRating = widget.food.cleanlinessRating;
      originalShelterCondition = widget.food.shelterCondition;
      originalSpecialNotes = widget.food.specialNotes;
      originalBowlCountFood = widget.food.bowlCountFood;
      originalBowlCountWater = widget.food.bowlCountWater;
      originalBowlSize = widget.food.bowlSize;
      originalBowlCleanliness = widget.food.bowlCleanliness;
      originalFoodRemain = widget.food.foodRemain;
      originalWaterRemain = widget.food.waterRemain;
      originalFoodType = widget.food.foodType;
    });
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Colors.black87),
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

      print('API 응답: ${response.body}');

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
      print('주소 변환 실패: ${response.statusCode}');
      return null;
    } catch (e) {
      print('주소 변환 중 오류 발생: $e');
      return null;
    }
  }

  Future<void> _showImagePicker() async {
    try {
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
            imageDateTime = formatDateTimeRegExp(exifResult['imageDateTime']);
            feedingSpotLocation = exifResult['locationName'];
            // latitude = exifResult['latitude']; // 위도 정보는 사용하지 않음
            // longitude = exifResult['longitude']; // 경도 정보는 사용하지 않음
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
    // 필수 필드 체크
    bool hasRequiredFields = savedImagePath != null &&
        feedingSpotLocation != null &&
        feedingSpotLocation!.isNotEmpty &&
        feedingMethod != null &&
        feedingMethod != "선택" &&
        cleanlinessRating != null &&
        cleanlinessRating != "선택" &&
        shelterCondition != null &&
        shelterCondition != "선택";
    // 변경사항 체크
    bool hasChanges = savedImagePath != originalImagePath ||
        imageDateTime != originalImageDateTime ||
        feedingSpotLocation != originalFeedingSpotLocation ||
        detailLocation != originalDetailLocation ||
        feedingMethod != originalFeedingMethod ||
        cleanlinessRating != originalCleanlinessRating ||
        shelterCondition != originalShelterCondition ||
        specialNotes != originalSpecialNotes ||
        bowlCountFood != originalBowlCountFood ||
        bowlCountWater != originalBowlCountWater ||
        bowlSize != originalBowlSize ||
        bowlCleanliness != originalBowlCleanliness ||
        foodRemain != originalFoodRemain ||
        waterRemain != originalWaterRemain ||
        foodType != originalFoodType;
    return hasRequiredFields && hasChanges;
  }

  String _getUpdateButtonText() {
    bool hasChanges = savedImagePath != originalImagePath ||
        imageDateTime != originalImageDateTime ||
        feedingSpotLocation != originalFeedingSpotLocation ||
        detailLocation != originalDetailLocation ||
        feedingMethod != originalFeedingMethod ||
        cleanlinessRating != originalCleanlinessRating ||
        shelterCondition != originalShelterCondition ||
        specialNotes != originalSpecialNotes ||
        bowlCountFood != originalBowlCountFood ||
        bowlCountWater != originalBowlCountWater ||
        bowlSize != originalBowlSize ||
        bowlCleanliness != originalBowlCleanliness ||
        foodRemain != originalFoodRemain ||
        waterRemain != originalWaterRemain ||
        foodType != originalFoodType;
    return hasChanges ? '수정' : '변경사항 없음';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("급식 정보 수정", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5, left: 10),
                      child: Text(
                        "NO. ${widget.food.feedingSpotLocation}",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _showImagePicker,
                  child: _buildPhotoArea(),
                ),
                SizedBox(height: 14),
                _buildLabel("발견 시간"),
                SizedBox(height: 4),
                _buildInfoBox(
                  icon: Icons.access_time,
                  text: imageDateTime ?? '시간 정보 없음',
                ),
                SizedBox(height: 14),
                _buildLabel("급식 위치"),
                SizedBox(height: 4),
                _buildInfoBox(
                  icon: Icons.location_on,
                  text: feedingSpotLocation ?? '위치 정보 없음',
                ),
                SizedBox(height: 14),
                _buildLabel("상세 주소"),
                SizedBox(height: 4),
                TextField(
                  controller: _detailLocationController,
                  decoration: InputDecoration(
                    hintText: '상세 주소를 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (v) => setState(() => detailLocation = v),
                ),
                SizedBox(height: 14),
                _buildLabel("급여 방식"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: feedingMethodItems,
                  value: feedingMethod ?? feedingMethodItems[0],
                  onChanged: (v) => setState(() => feedingMethod = v),
                ),
                SizedBox(height: 14),
                _buildLabel("청결도 평가"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: cleanlinessRatingItems,
                  value: cleanlinessRating ?? cleanlinessRatingItems[0],
                  onChanged: (v) => setState(() => cleanlinessRating = v),
                ),
                SizedBox(height: 14),
                _buildLabel("쉼터 상태"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: shelterConditionItems,
                  value: shelterCondition ?? shelterConditionItems[0],
                  onChanged: (v) => setState(() => shelterCondition = v),
                ),
                SizedBox(height: 14),
                _buildLabel("밥그릇 수"),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: '밥그릇 수를 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  controller: TextEditingController(text: bowlCountFood ?? ''),
                  onChanged: (v) => setState(() => bowlCountFood = v),
                ),
                SizedBox(height: 14),
                _buildLabel("물그릇 수"),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: '물그릇 수를 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  controller: TextEditingController(text: bowlCountWater ?? ''),
                  onChanged: (v) => setState(() => bowlCountWater = v),
                ),
                SizedBox(height: 14),
                _buildLabel("그릇 크기"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: bowlSizeItems,
                  value: bowlSize ?? bowlSizeItems[0],
                  onChanged: (v) => setState(() => bowlSize = v),
                ),
                SizedBox(height: 14),
                _buildLabel("그릇 청결 정도"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: bowlCleanlinessItems,
                  value: bowlCleanliness ?? bowlCleanlinessItems[0],
                  onChanged: (v) => setState(() => bowlCleanliness = v),
                ),
                SizedBox(height: 14),
                _buildLabel("사료 잔여 여부"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: foodRemainItems,
                  value: foodRemain ?? foodRemainItems[0],
                  onChanged: (v) => setState(() => foodRemain = v),
                ),
                SizedBox(height: 14),
                _buildLabel("물 잔여 여부"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: waterRemainItems,
                  value: waterRemain ?? waterRemainItems[0],
                  onChanged: (v) => setState(() => waterRemain = v),
                ),
                SizedBox(height: 14),
                _buildLabel("사료 종류"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: foodTypeItems,
                  value: foodType ?? foodTypeItems[0],
                  onChanged: (v) => setState(() => foodType = v),
                ),
                SizedBox(height: 14),
                _buildLabel("특이사항"),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: '예) 사료가 부족함, 그릇이 깨짐 등',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 2,
                  controller: _specialNotesController,
                  onChanged: (v) => setState(() {
                    specialNotes = v;
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          minimumSize: Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isFormValid ? Colors.teal : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          minimumSize: Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isFormValid ? _onUpdatePressed : null,
                        child: Text(
                          _getUpdateButtonText(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onUpdatePressed() async {
    if (savedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지를 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (feedingSpotLocation == null ||
        feedingSpotLocation!.isEmpty ||
        feedingMethod == null ||
        feedingMethod == "선택" ||
        cleanlinessRating == null ||
        cleanlinessRating == "선택" ||
        shelterCondition == null ||
        shelterCondition == "선택") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 선택해주세요.')),
      );
      return;
    }

    try {
      final updatedFood = Food(
        feedingSpotLocation: feedingSpotLocation!,
        feedingMethod: feedingMethod!,
        cleanlinessRating: cleanlinessRating!,
        shelterCondition: shelterCondition!,
        specialNotes: specialNotes,
        image: savedImagePath!,
        discoveryTime: imageDateTime ?? '',
        detailLocation: detailLocation ?? '-',
        bowlCountFood: bowlCountFood,
        bowlCountWater: bowlCountWater,
        bowlSize: bowlSize,
        bowlCleanliness: bowlCleanliness,
        foodRemain: foodRemain,
        waterRemain: waterRemain,
        foodType: foodType,
      );

      await FoodDatabase.instance.updateFood(updatedFood);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('급식 정보가 수정되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, updatedFood);
      }
    } catch (e) {
      print('데이터 수정 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('데이터 수정 중 오류가 발생했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('급식 정보 삭제'),
          content: Text('정말로 이 급식 정보를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteFood();
              },
              child: Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFood() async {
    try {
      await FoodDatabase.instance.deleteFood(widget.food.feedingSpotLocation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('급식 정보가 삭제되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('데이터 삭제 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('데이터 삭제 중 오류가 발생했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 발견 시간 위젯
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

  // 날짜 데이터 형식 변환
  String formatDateTimeRegExp(String inputDateTime) {
    try {
      RegExp regExp = RegExp(
        r"^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})$",
      );
      if (!regExp.hasMatch(inputDateTime)) {
        throw FormatException(
          "입력 문자열이 'YYYY:MM:DD HH:MM:SS' 정규식과 일치하지 않습니다.",
          inputDateTime,
        );
      }
      return inputDateTime.replaceAllMapped(regExp, (match) {
        return "${match.group(1)}년${match.group(2)}월${match.group(3)}일 ${match.group(4)}시${match.group(5)}분${match.group(6)}초";
      });
    } catch (e) {
      print("formatDateTimeRegExp 오류: $e");
      return "입력 형식 오류";
    }
  }
}
