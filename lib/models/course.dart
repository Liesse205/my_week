import 'dart:convert';

class Course {
  String name;
  String day;
  int start;
  int end;

  Course({
    required this.name,
    required this.day,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'day': day,
      'start': start,
      'end': end,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      name: json['name'] as String,
      day: json['day'] as String,
      start: json['start'] as int,
      end: json['end'] as int,
    );
  }
}