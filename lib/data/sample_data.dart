import '../models/course.dart';

List<Course> sampleCourses() => [
  Course(name: 'Maths',     day: 'Mon', start: 8 * 60,       end: 10 * 60),
  Course(name: 'Physics',   day: 'Mon', start: 10 * 60,      end: 11 * 60 + 30),
  Course(name: 'Chemistry', day: 'Tue', start: 9 * 60,       end: 10 * 60 + 30),
  Course(name: 'English',   day: 'Wed', start: 14 * 60,      end: 15 * 60 + 30),
  Course(name: 'Biology',   day: 'Wed', start: 15 * 60,      end: 16 * 60 + 30),
  Course(name: 'Lab',       day: 'Wed', start: 15 * 60 + 15, end: 16 * 60 + 45), // Deliberate clash
];