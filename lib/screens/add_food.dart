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
  static const String KAKAO_API_KEY = '4faeb42201cf02a0d3555f161c3879ad';

  // 드롭다운 아이템 리스트
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
  // 추가: 드롭다운 항목 리스트
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

  // 시간 선택 관련 변수
  TimeOfDay? selectedTime;
  String get formattedTime {
    if (imageDateTime == null) {
      return '활동 시간을 선택해주세요';
    }
    return imageDateTime!;
  }

  // 1. 급식장소 TextField에 controller 사용
  // final TextEditingController feedingSpotController = TextEditingController(); // 삭제

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();
    DateTime initialDate = now;
    if (imageDateTime != null) {
      // "2025:05:30 15:03:09" → DateTime 파싱
      final reg = RegExp(r"^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})$");
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

  // 주요 발견 시간 위젯
  Widget _buildTimeInfoBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 6),
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
      margin: const EdgeInsets.only(bottom: 10),
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

  Widget _buildPhotoArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        savedImagePath != null
            ? SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(savedImagePath!), fit: BoxFit.cover),
                ),
              )
            : Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.grey.shade200,
                ),
                alignment: Alignment.center,
                child: Text(
                  '이미지 선택하기',
                  style: TextStyle(fontSize: 22, color: Colors.grey.shade600),
                ),
              ),
      ],
    );
  }

  Future<String?> _saveImageToAppDirectory(XFile imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final String filePath = '${appDir.path}/$fileName';
      final File newImage = await File(imageFile.path).copy(filePath);
      return newImage.path;
    } catch (e) {
      print('이미지 저장 오류: $e');
      return null;
    }
  }

  // 2. 이미지 선택 후 주소 자동 입력
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
          final exifResult = await _readExifDataForState(savedPath);
          setState(() {
            savedImagePath = savedPath;
            // 여기서 바로 한글 포맷으로 변환
            imageDateTime = exifResult['imageDateTime'] != null
                ? formatDateTimeKor(exifResult['imageDateTime'])
                : '';
            feedingSpotLocation = exifResult['locationName'] ?? '';
            // feedingSpotController.text = feedingSpotLocation; // 이 줄은 삭제!
          });
        }
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
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필수 항목을 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
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
        print(
            '저장된 급식 정보: ${savedFood.feedingSpotLocation} - ${savedFood.discoveryTime}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('급식 정보가 저장되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        print('=== add_food.dart에서 pop 호출 ===');
        print(
            'pop할 food 객체: ${food.feedingSpotLocation} - ${food.discoveryTime}');
        Navigator.of(context).pop(food); // 급식 정보 데이터와 함께 이전 화면으로 돌아가기
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

  Widget _buildInfoBox({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
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

  Future<Map<String, dynamic>> _readExifDataForState(String imagePath) async {
    String? newImageDateTime;
    String? newLocationName;
    double? newLatitude;
    double? newLongitude;
    try {
      final bytes = await File(imagePath).readAsBytes();
      final exifData = await readExifFromBytes(bytes);

      if (exifData.isEmpty) {
        return {
          'imageDateTime': null,
          'locationName': null,
          'latitude': null,
          'longitude': null,
        };
      }

      // 날짜/시간 정보 읽기
      if (exifData.containsKey('EXIF DateTimeOriginal')) {
        final dateTimeStr = exifData['EXIF DateTimeOriginal']?.printable;
        newImageDateTime = dateTimeStr;
      }

      // GPS 정보 읽기
      if (exifData.containsKey('GPS GPSLatitude') &&
          exifData.containsKey('GPS GPSLongitude')) {
        final latValue = exifData['GPS GPSLatitude']!;
        final lonValue = exifData['GPS GPSLongitude']!;
        final latRef = exifData['GPS GPSLatitudeRef']?.printable;
        final lonRef = exifData['GPS GPSLongitudeRef']?.printable;

        newLatitude = _convertGpsToDecimal(
          latValue.values.toList().cast<Ratio>(),
        );
        newLongitude = _convertGpsToDecimal(
          lonValue.values.toList().cast<Ratio>(),
        );

        if (latRef == 'S') newLatitude = -newLatitude!;
        if (lonRef == 'W') newLongitude = -newLongitude!;

        // 위도/경도를 도로명 주소로 변환
        if (newLatitude != null && newLongitude != null) {
          final address = await _getAddressFromCoordinates(
            newLatitude,
            newLongitude,
          );
          newLocationName = address ??
              '위도: ${newLatitude.toStringAsFixed(4)}, 경도: ${newLongitude.toStringAsFixed(4)}';
        }
      }

      return {
        'imageDateTime': newImageDateTime,
        'locationName': newLocationName,
        'latitude': newLatitude,
        'longitude': newLongitude,
      };
    } catch (e) {
      print('EXIF 데이터 읽기 오류: $e');
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
