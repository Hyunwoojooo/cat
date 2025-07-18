import 'package:flutter/material.dart';

class ListCat extends StatelessWidget {
  final String image;
  final String surveyTimestamp;
  final String surveyArea;
  const ListCat({
    required this.image,
    required this.surveyTimestamp,
    required this.surveyArea,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // image 파라미터 사용
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              image,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
            Text("조사 일시", style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),),
              Text(
                surveyTimestamp,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              SizedBox(height: 8,),
              Text("조사 장소", style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),),
              Text(
                surveyArea,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
