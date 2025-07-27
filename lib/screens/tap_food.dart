import 'package:flutter/material.dart';
import 'package:cat_project/models/food.dart';
import 'package:cat_project/screens/add_food.dart';
import 'package:cat_project/screens/info_food.dart';
import 'package:cat_project/database/food_db.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  List<Food> foodSurveys = [];
  Set<String> selectedFoods = {}; // 선택된 급식 정보들의 고유 ID를 저장
  Set<String> transmittedFoods = {}; // 전송된 급식 정보들의 고유 ID를 저장
  bool isSelectionMode = false; // 선택 모드인지 확인

  final dio = Dio();
  final url = 'http://catlove.o-r.kr:4000/api/food';
  final String transmittedFoodsKey = 'transmittedFoods';

  // 날짜 문자열을 ISO 8601 형식으로 변환하는 함수
  String _convertToISODateTime(String dateTimeStr) {
    try {
      // "2025년01월30일 15시03분09초" → "2025-01-30 15:03:09"
      final reg = RegExp(r"(\d{4})년(\d{2})월(\d{2})일 (\d{2})시(\d{2})분(\d{2})초");
      final match = reg.firstMatch(dateTimeStr);
      if (match != null) {
        final year = match.group(1);
        final month = match.group(2);
        final day = match.group(3);
        final hour = match.group(4);
        final minute = match.group(5);
        final second = match.group(6);
        return "$year-$month-$day $hour:$minute:$second";
      }
      return dateTimeStr; // 변환 실패 시 원본 반환
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  void initState() {
    super.initState();
    print('=== tap_food.dart initState 호출됨 ===');
    _loadFoods();
    _loadTransmittedFoods();
  }

  Future<void> _loadFoods() async {
    print('=== _loadFoods 메서드 시작 ===');
    try {
      print('급식 데이터 로딩 시작...');
      foodSurveys = await FoodDatabase.instance.getAllFoods();
      print('로드된 급식 정보 수: ${foodSurveys.length}');

      // 각 급식 정보에 고유 ID 부여 (인덱스 기반)
      for (int i = 0; i < foodSurveys.length; i++) {
        foodSurveys[i] = foodSurveys[i]
            .copyWith(uniqueId: '${foodSurveys[i].feedingSpotLocation}_$i');
        print(
            '급식 정보 ID: ${foodSurveys[i].feedingSpotLocation}, 고유 ID: ${foodSurveys[i].uniqueId}');
      }

      setState(() {});
      print('급식 데이터 로딩 완료');
    } catch (e) {
      print('급식 데이터 로딩 오류: $e');
    }
  }

  Future<void> _loadTransmittedFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(transmittedFoodsKey) ?? [];
    setState(() {
      transmittedFoods = ids.toSet();
    });
  }

  void _addFood(Food newFood) async {
    print('=== _addFood 메서드 호출 ===');
    print('추가할 급식 정보: ${newFood.feedingSpotLocation}');

    try {
      // 새로 추가된 급식 정보에 고유 ID 부여
      final uniqueFood = newFood.copyWith(
          uniqueId: '${newFood.feedingSpotLocation}_${foodSurveys.length}');
      setState(() {
        foodSurveys.add(uniqueFood);
      });
      print('_addFood 완료 - 목록에 추가됨 (고유 ID: ${uniqueFood.uniqueId})');
    } catch (e) {
      print('_addFood 오류: $e');
      // 오류 발생 시 데이터베이스에서 다시 로드
      await _loadFoods();
    }
  }

  // 급식 정보 선택/해제 함수 (고유 ID 사용)
  void _toggleFoodSelection(String uniqueId) {
    setState(() {
      if (selectedFoods.contains(uniqueId)) {
        selectedFoods.remove(uniqueId);
      } else {
        selectedFoods.add(uniqueId);
      }

      // 선택된 급식 정보가 없으면 선택 모드 해제
      if (selectedFoods.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  // 선택 모드 시작
  void _startSelectionMode() {
    setState(() {
      isSelectionMode = true;
    });
  }

  // 선택 모드 종료
  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedFoods.clear();
    });
  }

  // 전송 상태 초기화 (모든 급식 정보를 미전송 상태로)
  void _resetTransmissionStatus() async {
    setState(() {
      transmittedFoods.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(transmittedFoodsKey);
  }

  // 서버 전송 함수
  Future<void> _sendToServer(BuildContext context) async {
    // 선택된 급식 정보가 없으면 경고 메시지 표시
    if (selectedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('전송할 급식 정보를 선택해주세요.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("선택된 ${selectedFoods.length}개 전송 중..."),
              ],
            ),
          );
        },
      );

      // 선택된 급식 정보들만 필터링 (고유 ID 사용)
      final selectedFoodList = foodSurveys
          .where((food) => selectedFoods.contains(food.uniqueId))
          .toList();

      for (final food in selectedFoodList) {
        final imageFile = File(food.image);

        // 사용자 ID 가져오기
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        // 선택된 아이템의 DB id를 feedingSpotId로 사용
        final String feedingSpotId = (food.id ?? '').toString();

        final requestDto = {
          "userId": userId ?? "unknown",
          "feedingSpotId": "$userId-$feedingSpotId",
          "discoveryTime": _convertToISODateTime(food.discoveryTime),
          "feedingSpotLocation": food.feedingSpotLocation,
          "detailLocation": food.detailLocation,
          "feedingMethod": food.feedingMethod,
          "cleanlinessRating": food.cleanlinessRating,
          "shelterCondition": food.shelterCondition,
          "foodBowlCount": food.bowlCountFood,
          "waterBowlCount": food.bowlCountWater,
          "bowlSize": food.bowlSize,
          "bowlCleanliness": food.bowlCleanliness,
          "hasRemainingFood": food.foodRemain,
          "hasRemainingWater": food.waterRemain,
          "foodType": food.foodType,
          "specialNotes": food.specialNotes,
        };

        print(requestDto);

        final formData = FormData.fromMap({
          "requestDto": jsonEncode(requestDto),
          "file": await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });

        final response = await dio.post(
          url,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );

        print(response.data);
        print(response.statusCode);

        // 응답 처리 (필요시)
        if (response.statusCode != 200) {
          throw Exception('서버 응답 오류: ${response.statusCode}');
        }
      }

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      // 전송된 급식 정보들을 transmittedFoods에 추가
      setState(() {
        transmittedFoods.addAll(selectedFoods);
      });
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList(transmittedFoodsKey, transmittedFoods.toList());

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('선택된 ${selectedFoods.length}개가 성공적으로 전송되었습니다!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // 전송 완료 후 선택 모드 종료
      _exitSelectionMode();
    } catch (e, stack) {
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      print('전송 중 예외 발생: $e');
      print(stack);

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('전송 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isSelectionMode
          ? AppBar(
              title: Text('${selectedFoods.length}개 선택됨'),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              actions: [
                TextButton(
                  onPressed: _exitSelectionMode,
                  child: Text(
                    '취소',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            )
          : AppBar(
              title: Text('급식 정보 목록'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue),
                  onPressed: _loadFoods,
                  tooltip: '목록 새로고침',
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          print('=== FloatingActionButton 클릭됨 ===');
          final newFood = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddFood()),
          );
          print('=== AddFood에서 돌아옴 ===');
          print('newFood: $newFood');
          if (newFood != null && newFood is Food) {
            print('=== Food 객체 확인됨, _addFood 호출 ===');
            _addFood(newFood);
          } else {
            print('=== newFood이 null이거나 Food가 아님 ===');
            // newFood이 null이어도 데이터 새로고침
            await _loadFoods();
          }
        },
        elevation: 5,
        backgroundColor: Color(0xFFFFF8E1),
        icon: Icon(Icons.food_bank_rounded, size: 22, color: Color(0xFF8D6E63)),
        label: Text(
          '신규 급식 정보 추가',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF8D6E63),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      persistentFooterButtons: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _sendToServer(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedFoods.isNotEmpty ? Color(0xFF4CAF50) : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.cloud_upload, size: 20),
              label: Text(
                selectedFoods.isNotEmpty
                    ? '선택된 ${selectedFoods.length}개 전송'
                    : transmittedFoods.isNotEmpty
                        ? '미전송 ${foodSurveys.length - transmittedFoods.length}개'
                        : '서버로 데이터 전송',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
      body: ListView.builder(
        itemCount: foodSurveys.length,
        itemBuilder: (context, index) {
          final food = foodSurveys[index];
          final isSelected = selectedFoods.contains(food.uniqueId);
          final isTransmitted = transmittedFoods.contains(food.uniqueId);

          return GestureDetector(
            onTap: () async {
              if (isSelectionMode) {
                // 선택 모드일 때는 선택/해제
                _toggleFoodSelection(food.uniqueId!);
              } else {
                // 일반 모드일 때는 상세 페이지로 이동
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InfoFood(food: food),
                  ),
                );
                if (result != null) {
                  _loadFoods(); // 데이터가 수정되었으면 목록을 새로고침
                }
              }
            },
            onLongPress: () {
              // 길게 누르면 선택 모드 시작
              if (!isSelectionMode) {
                _startSelectionMode();
                _toggleFoodSelection(food.uniqueId!);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange.withOpacity(0.1)
                    : isTransmitted
                        ? Colors.green.withOpacity(0.05)
                        : Colors.transparent,
                border: isSelected
                    ? Border.all(color: Colors.orange, width: 2)
                    : isTransmitted
                        ? Border.all(color: Colors.green, width: 1)
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 18, top: 8),
                    child: Row(
                      children: [
                        Text('No.${index + 1}', style: TextStyle(fontSize: 18)),
                        if (isTransmitted) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '전송됨',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8, right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이미지
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Image.file(
                            File(food.image),
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '발견 시간',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                food.discoveryTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '급식 위치',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                food.feedingSpotLocation,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 1,
                    margin: const EdgeInsets.only(top: 8),
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
