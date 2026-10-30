import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Course {
  String id;
  String name;
  String day;
  int start;
  int end;

  Course({
    this.id = '',
    required this.name,
    required this.day,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'day': day,
      'start': start,
      'end': end,
    };
  }

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Course(
      id: doc.id,
      name: data['name'] as String,
      day: data['day'] as String,
      start: (data['start'] as num).toInt(),
      end: (data['end'] as num).toInt(),
    );
  }
}

CollectionReference<Map<String, dynamic>> myCourses() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance.collection('users').doc(uid).collection('courses');
}