import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import '../repositories/photo_repository.dart';
import '../data/sample_data.dart';

class CourseState extends ChangeNotifier {
  CourseState(this._repo, this._photos) {
    _subscription = _repo.watchAll().listen(
          (list) {
        _courses = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load courses.';
        notifyListeners();
      },
    );
  }

  final CourseRepository _repo;
  final PhotoRepository _photos;
  StreamSubscription<List<Course>>? _subscription;

  List<Course> _courses = [];
  bool _loading = true;
  String? _error;

  String _filter = 'all';
  String _query = '';

  List<Course> get courses => _courses;
  bool get loading => _loading;
  String? get error => _error;

  String get filter => _filter;
  String get query => _query;

  int get weekTotal => _courses.fold(0, (s, c) => s + (c.end - c.start));

  List<Course> get visible {
    var list = _courses;

    if (_filter != 'all') {
      list = list.where((c) => c.day == _filter).toList();
    }

    if (_query.isNotEmpty) {
      list = list.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
    }

    return list;
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<String> uploadPhoto(File photo) => _photos.upload(photo);

  Future<void> add(Course course) => _repo.add(course);
  Future<void> edit(String id, Course course) => _repo.update(id, course);
  Future<void> remove(Course course) => _repo.delete(course.id);
  Future<void> addSamples() => _repo.addSamples(sampleCourses());

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}