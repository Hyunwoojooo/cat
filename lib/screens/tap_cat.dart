// tap_cat.dart
import 'package:cat_project/screens/add_cat.dart';
import 'package:cat_project/screens/info_cat.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:cat_project/components/list_cat.dart'; // path 맞게 수정
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cat_project/models/cat.dart';
import 'package:cat_project/database/cat_db.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CatListScreen extends StatefulWidget {
  const CatListScreen({super.key});

  @override
  State<CatListScreen> createState() => _CatListScreenState();
}

class _CatListScreenState extends State<CatListScreen> {
  List<Cat> catSurveys = [];
  Set<String> selectedCats = {}; // 선택된 고양이들의 고유 ID를 저장
  Set<String> transmittedCats = {}; // 전송된 고양이들의 고유 ID를 저장
  bool isSelectionMode = false; // 선택 모드인지 확인

  final dio = Dio();
  final url = 'http://catlove.o-r.kr:4000/api/cat';

  @override
  void initState() {
    super.initState();
    print('=== tap_cat.dart initState 호출됨 ===');
    _loadCats();
  }

  Future<void> _loadCats() async {
    print('=== _loadCats 메서드 시작 ===');
    try {
      print('고양이 데이터 로딩 시작...');
      catSurveys = await CatDatabase.instance.getAllCats();
      print('로드된 고양이 수: ${catSurveys.length}');

      // 각 고양이에 고유 ID 부여 (인덱스 기반)
      for (int i = 0; i < catSurveys.length; i++) {
        catSurveys[i] =
            catSurveys[i].copyWith(uniqueId: '${catSurveys[i].catId}_$i');
        print(
            '고양이 ID: ${catSurveys[i].catId}, 고유 ID: ${catSurveys[i].uniqueId}, 위치: ${catSurveys[i].location}');
      }

      setState(() {});
      print('고양이 데이터 로딩 완료');
    } catch (e) {
      print('고양이 데이터 로딩 오류: $e');
    }
  }

  void _addCat(Cat newCat) async {
    print('=== _addCat 메서드 호출 ===');
    print('추가할 고양이: ${newCat.catId} - ${newCat.location}');

    try {
      // 새로 추가된 고양이에 고유 ID 부여
      final uniqueCat =
          newCat.copyWith(uniqueId: '${newCat.catId}_${catSurveys.length}');
      setState(() {
        catSurveys.add(uniqueCat);
      });
      print('_addCat 완료 - 목록에 추가됨 (고유 ID: ${uniqueCat.uniqueId})');
    } catch (e) {
      print('_addCat 오류: $e');
      // 오류 발생 시 데이터베이스에서 다시 로드
      await _loadCats();
    }
  }

  // 고양이 선택/해제 함수 (고유 ID 사용)
  void _toggleCatSelection(String uniqueId) {
    setState(() {
      if (selectedCats.contains(uniqueId)) {
        selectedCats.remove(uniqueId);
      } else {
        selectedCats.add(uniqueId);
      }

      // 선택된 고양이가 없으면 선택 모드 해제
      if (selectedCats.isEmpty) {
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
      selectedCats.clear();
    });
  }

  // 전송 상태 초기화 (모든 고양이를 미전송 상태로)
  void _resetTransmissionStatus() {
    setState(() {
      transmittedCats.clear();
    });
  }

  // 서버 전송 함수
  Future<void> _sendToServer(BuildContext context) async {
    // 선택된 고양이가 없으면 경고 메시지 표시
    if (selectedCats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('전송할 고양이를 선택해주세요.'),
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
                Text("선택된 ${selectedCats.length}마리 전송 중..."),
              ],
            ),
          );
        },
      );

      // 선택된 고양이들만 필터링 (고유 ID 사용)
      final selectedCatList = catSurveys
          .where((cat) => selectedCats.contains(cat.uniqueId))
          .toList();

      for (final cat in selectedCatList) {
        final imageFile = File(cat.image);

        // 사용자 ID 가져오기
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        final requestDto = {
          "userId": userId ?? "unknown",
          "keyDiscoveryTime": cat.keyDiscoveryTime,
          "catId": "$userId-${cat.catId}",
          "location": cat.location,
          "detailLocation": cat.detailLocation,
          "furColor": cat.furColor,
          "age": cat.age,
          "eyeColor": cat.eyeColor,
          "pattern": cat.pattern,
          "isNeutered": cat.isNeutered,
          "specialNotes": cat.specialNotes,
          "isDuplicate": cat.isDuplicate,
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

      // 전송된 고양이들을 transmittedCats에 추가
      setState(() {
        transmittedCats.addAll(selectedCats);
      });

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('선택된 ${selectedCats.length}마리가 성공적으로 전송되었습니다!'),
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
      print(stack); // 스택 트레이스까지 보고 싶으면 추가

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
              title: Text('${selectedCats.length}마리 선택됨'),
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
              title: Text('고양이 목록'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue),
                  onPressed: _loadCats,
                  tooltip: '목록 새로고침',
                ),
                if (transmittedCats.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.blue),
                    onPressed: _resetTransmissionStatus,
                    tooltip: '전송 상태 초기화',
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          print('=== FloatingActionButton 클릭됨 ===');
          final newCat = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCat(number: catSurveys.length),
            ),
          );
          print('=== AddCat에서 돌아옴 ===');
          print('newCat: $newCat');
          if (newCat != null && newCat is Cat) {
            print('=== Cat 객체 확인됨, _addCat 호출 ===');
            _addCat(newCat);
          } else {
            print('=== newCat이 null이거나 Cat이 아님 ===');
            // newCat이 null이어도 데이터 새로고침
            await _loadCats();
          }
        },
        elevation: 5,
        backgroundColor: Color(0xFFFFF8E1),
        icon: Icon(Icons.pets, size: 22, color: Color(0xFF8D6E63)),
        label: Text(
          '신규 고양이 추가',
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
                    selectedCats.isNotEmpty ? Color(0xFF4CAF50) : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.cloud_upload, size: 20),
              label: Text(
                selectedCats.isNotEmpty
                    ? '선택된 ${selectedCats.length}마리 전송'
                    : transmittedCats.isNotEmpty
                        ? '미전송 ${catSurveys.length - transmittedCats.length}마리'
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
        itemCount: catSurveys.length,
        itemBuilder: (context, index) {
          final cat = catSurveys[index];
          final isSelected = selectedCats.contains(cat.uniqueId);
          final isTransmitted = transmittedCats.contains(cat.uniqueId);

          return GestureDetector(
            onTap: () async {
              if (isSelectionMode) {
                // 선택 모드일 때는 선택/해제
                _toggleCatSelection(cat.uniqueId!);
              } else {
                // 일반 모드일 때는 상세 페이지로 이동
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InfoCat(cat: cat),
                  ),
                );
                if (result != null) {
                  _loadCats(); // 데이터가 수정되었으면 목록을 새로고침
                }
              }
            },
            onLongPress: () {
              // 길게 누르면 선택 모드 시작
              if (!isSelectionMode) {
                _startSelectionMode();
                _toggleCatSelection(cat.uniqueId!);
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
                        Text('No.${cat.catId}', style: TextStyle(fontSize: 18)),
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
                        // 이미지 및 번호
                        Container(
                          width: 90,
                          height: 90,
                          child: cat.image.startsWith('assets/')
                              ? Image.asset(cat.image, fit: BoxFit.cover)
                              : Image.file(
                                  File(cat.image),
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
                                '주요 발견 시간',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                cat.keyDiscoveryTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '주요 발견 장소',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                cat.location,
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
