import 'package:dio/dio.dart';
import 'dart:convert';

  // // 서버 전송 함수
  // Future<void> _sendToServer(BuildContext context) async {
  //   // 선택된 고양이가 없으면 경고 메시지 표시
  //   if (selectedCats.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('전송할 고양이를 선택해주세요.'),
  //         backgroundColor: Colors.orange,
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //     return;
  //   }

  //   try {
  //     // 로딩 다이얼로그 표시
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (BuildContext dialogContext) {
  //         return AlertDialog(
  //           content: Row(
  //             children: [
  //               CircularProgressIndicator(),
  //               SizedBox(width: 20),
  //               Text("선택된 ${selectedCats.length}마리 전송 중..."),
  //             ],
  //           ),
  //         );
  //       },
  //     );

  //     // 선택된 고양이들만 필터링
  //     final selectedCatList =
  //         catSurveys.where((cat) => selectedCats.contains(cat.number)).toList();

  //     // 여기에 실제 서버 전송 로직을 구현하세요
  //     // 예시: HTTP 요청을 통해 데이터 전송
  //     await Future.delayed(Duration(seconds: 2)); // 임시 딜레이

  //     // 로딩 다이얼로그 닫기
  //     Navigator.of(context).pop();

  //     // 전송된 고양이들을 transmittedCats에 추가
  //     setState(() {
  //       transmittedCats.addAll(selectedCats);
  //     });

  //     // 성공 메시지 표시
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('선택된 ${selectedCats.length}마리가 성공적으로 전송되었습니다!'),
  //         backgroundColor: Colors.green,
  //         duration: Duration(seconds: 3),
  //       ),
  //     );

  //     // 전송 완료 후 선택 모드 종료
  //     _exitSelectionMode();
  //   } catch (e) {
  //     // 로딩 다이얼로그 닫기
  //     Navigator.of(context).pop();

  //     // 에러 메시지 표시
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('전송 중 오류가 발생했습니다: $e'),
  //         backgroundColor: Colors.red,
  //         duration: Duration(seconds: 3),
  //       ),
  //     );
  //   }
  // }