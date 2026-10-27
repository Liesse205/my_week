import '../models/course.dart';
import 'time_utils.dart';

const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

bool clash(Course a, Course b) {
  if (a.day != b.day) return false;
  return a.start < b.end && b.start < a.end;
}

List<Course> clashesWith(Course target, List<Course> all) {
  return all.where((c) => !identical(c, target) && clash(target, c)).toList();
}

List<Course> sortedByStart(List<Course> dayCourses) {
  final copy = [...dayCourses];
  copy.sort((a, b) => a.start.compareTo(b.start));
  return copy;
}

int dayTotalMinutes(List<Course> dayCourses) =>
    dayCourses.fold(0, (sum, c) => sum + (c.end - c.start));

Map<String, List<Course>> groupByDay(List<Course> all) {
  final map = <String, List<Course>>{};
  for (final d in days) {
    map[d] = sortedByStart(all.where((c) => c.day == d).toList());
  }
  return map;
}

String? validateCourse({
  required String name,
  required String startRaw,
  required String endRaw,
  required List<Course> existing,
  Course? editing,
}) {
  if (name.trim().isEmpty) return 'Course name cannot be empty';

  final start = parseTime(startRaw);
  if (start == null) return 'Start time must be HH:MM (e.g. 08:00)';

  final end = parseTime(endRaw);
  if (end == null) return 'End time must be HH:MM (e.g. 10:00)';

  if (end <= start) return 'End time must be after start time';

  final dup = existing.any((c) =>
  !identical(c, editing) &&
      c.name.toLowerCase() == name.trim().toLowerCase());
  if (dup) return 'A course with that name already exists';

  return null;
}