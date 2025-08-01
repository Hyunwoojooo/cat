import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cat_project/main.dart';
import '../components/colors.dart';
import '../database/cat_db.dart';
import '../models/cat.dart';
import 'package:exif/exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import 'package:cat_project/components/colors.dart';

class AddCat extends StatefulWidget {
  final int number;
  const AddCat({required this.number, super.key});

  @override
  State<AddCat> createState() => _AddCatState();
}

class _AddCatState extends State<AddCat> {
  final picker = ImagePicker();
  String? savedImagePath;
  String hour = '333';
  String minute = '00';
  String? moimTime = '';
  int furNumber = 0;
  String specialNotes = '';

  // 위치 정보 변수 추가
  double? latitude;
  double? longitude;
  String? locationName;
  String? imageDateTime;

  String? selectedFurValue;
  String? selectedNeuteringValue = "선택";
  String? selectedEyesColor;
  String? selectedAge = "선택";
  String? selectedPattern = "선택";
  String? selectedDetailLocation = "선택";
  int isDuplicateValue = 0; // 중복 고양이 여부 (0: 중복 아님, 1: 중복)

  final List<String> neuteringItems = ["선택", "O", "X"];
  final List<String> ageItems = ["선택", "성묘", "자묘"];
  final List<String> patternItems = [
    "선택",
    '1. 단일색',
    "2. 두가지색",
    "3. 삼색",
    "4. 턱시도",
    "5. 로켓",
    "6. 미트",
    "7. 할리퀸",
    "8. 밴",
    "9. 톨티",
    "10. 고등어",
    "11. 줄무늬",
    "12. 점무늬",
    "13. 태비",
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
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: B_1,
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
        border: Border.all(color: B_4),
        borderRadius: BorderRadius.circular(40),
        color: P_3,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: P_1,
          ),
          style: TextStyle(fontSize: 15, color: B_1),
          dropdownColor: P_3,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(20),
          menuMaxHeight: 200,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15,
                      color: B_1,
                    ),
                  ),
                ),
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
        color: color ?? WHITE,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: B_4),
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
                    color: WHITE,
                    border: Border.all(color: B_4),
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
      return '활동 시간을 선택해주세요';
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

  Cat? _selectedDuplicateCat;

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
      if (Platform.isAndroid) {
        await Permission.storage.request();
        await Permission.photos.request(); // Android 13+
      }

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) {
        print('이미지가 선택되지 않았습니다.');
        return;
      }

      final file = File(pickedFile.path);
      if (!file.existsSync()) {
        print('선택한 이미지 파일이 존재하지 않습니다: ${pickedFile.path}');
        return;
      }

      // 이후 저장 및 setState
      final String? savedPath = await _saveImageToAppDirectory(pickedFile);
      if (savedPath != null) {
        // EXIF 데이터 먼저 읽고, 그 결과를 setState에서 한 번에 반영
        final exifResult = await _readExifDataForState(savedPath);
        setState(() {
          savedImagePath = savedPath;
          imageDateTime = formatDateTimeRegExp(exifResult['imageDateTime']);
          locationName = exifResult['locationName'];
          latitude = exifResult['latitude'];
          longitude = exifResult['longitude'];
        });
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

      print('=== EXIF DATA START ===');
      exifData.forEach((key, value) {
        print('$key: ${value.printable}');
      });
      print('=== EXIF DATA END ===');

      if (exifData.isEmpty) {
        print('EXIF 데이터가 비어 있습니다.');
        return {
          'imageDateTime': null,
          'locationName': null,
          'latitude': null,
          'longitude': null,
        };
      }
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
        selectedFurValue != null &&
        selectedFurValue!.isNotEmpty &&
        selectedAge != "선택" &&
        selectedEyesColor != null &&
        selectedEyesColor!.isNotEmpty &&
        selectedPattern != "선택" &&
        selectedNeuteringValue != "선택";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("신규 고양이 추가", style: TextStyle(color: B_1)),
        backgroundColor: WHITE,
        iconTheme: IconThemeData(color: B_1),
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
                      child: FutureBuilder<String>(
                        future: _getDisplayNumber(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? "NO. ${widget.number + 1}",
                            style: TextStyle(
                              color: B_1,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                    _buildDuplicateSelector(),
                  ],
                ),

                // 이미지 선택
                GestureDetector(
                  onTap: _showImagePicker,
                  child: _buildPhotoArea(),
                ),
                SizedBox(height: 14),
                _buildLabel("주요 발견 시간"),
                SizedBox(height: 4),
                _buildTimeInfoBox(),
                SizedBox(height: 14),
                _buildLabel("주요 발견 장소"),
                SizedBox(height: 4),
                _buildInfoBox(
                  icon: Icons.location_on,
                  text: locationName ?? '위치 정보 없음',
                ),
                SizedBox(height: 14),
                _buildLabel("상세 주소"),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: '상세 주소를 입력해주세요',
                    filled: true,
                    fillColor: WHITE,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: B_4),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (v) => setState(() => selectedDetailLocation = v),
                ),
                SizedBox(height: 14),
                _buildLabel("털 색"),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: '털 색을 입력해주세요 (예: 검정, 갈색, 흰색 등)',
                    filled: true,
                    fillColor: WHITE,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: B_4),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (v) => setState(() => selectedFurValue = v),
                ),
                SizedBox(height: 14),
                _buildLabel("나이"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: ageItems,
                  value: selectedAge!,
                  onChanged: (v) => setState(() => selectedAge = v),
                ),
                SizedBox(height: 14),
                _buildLabel("눈 색"),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: '눈 색을 입력해주세요 (예: 검정, 녹색, 갈색 등)',
                    filled: true,
                    fillColor: WHITE,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: B_4),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (v) => setState(() => selectedEyesColor = v),
                ),
                SizedBox(height: 14),
                _buildPatternLabelWithHelp(),
                SizedBox(height: 4),
                _buildDropdown(
                  items: patternItems,
                  value: selectedPattern!,
                  onChanged: (v) => setState(() => selectedPattern = v),
                ),
                SizedBox(height: 14),
                _buildLabel("중성화 여부"),
                SizedBox(height: 4),
                _buildDropdown(
                  items: neuteringItems,
                  value: selectedNeuteringValue!,
                  onChanged: (v) => setState(() => selectedNeuteringValue = v),
                ),
                SizedBox(height: 14),
                _buildLabel("특이사항"),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: '예) 오른쪽 귀가 잘림, 꼬리가 짧음 등',
                    filled: true,
                    fillColor: WHITE,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: B_4),
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
                      backgroundColor: isFormValid ? P_1 : B_3,
                      foregroundColor: WHITE,
                      minimumSize: Size(double.infinity, 52),
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

    if (selectedFurValue == null ||
        selectedFurValue!.isEmpty ||
        selectedAge == "선택" ||
        selectedEyesColor == null ||
        selectedEyesColor!.isEmpty ||
        selectedPattern == "선택" ||
        selectedNeuteringValue == "선택") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 항목을 선택해주세요.')));
      return;
    }

    try {
      String number;

      if (_selectedDuplicateCat != null) {
        // 중복 고양이는 모체와 동일한 번호 사용
        number = _selectedDuplicateCat!.catId;
      } else {
        number = (widget.number + 1).toString();
      }

      print('저장할 고양이 정보:');
      print('catId: $number');
      print('keyDiscoveryTime: ${imageDateTime ?? ""}');
      print('location: ${locationName ?? ""}');
      print('detailLocation: ${selectedDetailLocation ?? "-"}');
      print('furColor: $selectedFurValue');
      print('age: $selectedAge');
      print('isNeutered: ${selectedNeuteringValue == "O"}');
      print('specialNotes: ${specialNotes ?? "-"}');
      print('image: $savedImagePath');
      print('pattern: $selectedPattern');
      print('eyeColor: $selectedEyesColor');
      print('isDuplicate: $isDuplicateValue');

      final cat = Cat(
        catId: number,
        keyDiscoveryTime: imageDateTime ?? '',
        location: locationName ?? '',
        detailLocation: selectedDetailLocation ?? '-',
        furColor: selectedFurValue!,
        age: selectedAge!,
        isNeutered: selectedNeuteringValue == 'O',
        specialNotes: specialNotes ?? '-',
        image: savedImagePath!,
        pattern: selectedPattern!,
        eyeColor: selectedEyesColor!,
        isDuplicate: isDuplicateValue,
      );

      final result = await CatDatabase.instance.insertCat(cat);
      print('데이터베이스 저장 결과: $result');

      // 저장 후 즉시 확인
      final savedCats = await CatDatabase.instance.getAllCats();
      print('저장 후 전체 고양이 수: ${savedCats.length}');
      for (var savedCat in savedCats) {
        print('저장된 고양이: ${savedCat.catId} - ${savedCat.location}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('고양이 정보가 저장되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        print('=== add_cat.dart에서 pop 호출 ===');
        print('pop할 cat 객체: ${cat.catId} - ${cat.location}');
        Navigator.of(context).pop(cat); // 고양이 데이터와 함께 이전 화면으로 돌아가기
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

  Widget _buildDuplicateSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_selectedDuplicateCat != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  setState(() {
                    _selectedDuplicateCat = null;
                    isDuplicateValue = 0; // 중복 고양이 선택 해제 시 0으로 설정
                  });
                },
                child: Text(
                  "해제",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: BROWN,
              backgroundColor: P_3,
              side: BorderSide(color: B_4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
            onPressed: _showDuplicateSelector,
            child: Text(
              _selectedDuplicateCat != null
                  ? "선택: No.${_selectedDuplicateCat!.catId}"
                  : "중복 고양이 선택",
              style: TextStyle(
                color: BROWN,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDuplicateSelector() async {
    final cats = await CatDatabase.instance.getAllCats();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: cats.length,
          itemBuilder: (context, index) {
            final cat = cats[index];
            return ListTile(
              leading: cat.image.startsWith('assets/')
                  ? Image.asset(cat.image, width: 40, height: 40)
                  : Image.file(File(cat.image), width: 40, height: 40),
              title: Text('No.${cat.catId}'),
              subtitle: Text(cat.location),
              onTap: () {
                setState(() {
                  _selectedDuplicateCat = cat;
                  isDuplicateValue = 1; // 중복 고양이 선택 시 1로 설정
                });
                Navigator.pop(context);
                // 번호 업데이트를 위해 다시 빌드
                setState(() {});
              },
            );
          },
        );
      },
    );
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

  // 표시할 번호를 계산하는 메서드
  Future<String> _getDisplayNumber() async {
    if (_selectedDuplicateCat != null) {
      return "NO. ${_selectedDuplicateCat!.catId}";
    } else {
      return "NO. ${widget.number + 1}";
    }
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

  // 패턴 라벨 + 도움말 버튼
  Widget _buildPatternLabelWithHelp() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLabel("패턴"),
        SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/info_cat.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
          child: Icon(
            Icons.help_outline,
            color: Colors.grey,
            size: 20,
          ),
        ),
      ],
    );
  }
}
