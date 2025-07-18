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
            locationName = exifResult['locationName'];
            latitude = exifResult['latitude'];
            longitude = exifResult['longitude'];
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
        print("--------------------------------");
        print('EXIF dateTimeStr: $dateTimeStr');
        print("dataTimeStr: ${dateTimeStr.runtimeType}");
        newImageDateTime = dateTimeStr;
      }
      print("--------------------------------");
      print('newImageDateTime: $newImageDateTime');

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
        title: Text("신규 고양이 추가", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
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
                              color: Colors.black87,
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (v) => setState(() => selectedEyesColor = v),
                ),
                SizedBox(height: 14),
                _buildLabel("패턴"),
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
              backgroundColor: BROWN_LIGHT,
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
}
