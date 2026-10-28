import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../data/sample_data.dart';
import '../logic/time_utils.dart';
import '../logic/course_rules.dart';
import 'edit_course_screen.dart';
import '../weather.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});
  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  List<Course> courses = [];
  String selectedDay = 'Mon';

  Weather? weather;
  bool weatherLoading = true;
  String? weatherError;

  @override
  void initState() {
    super.initState();
    loadCourses();
    loadWeather();
  }

  Future<void> loadWeather() async {
    setState(() {
      weatherLoading = true;
      weatherError = null;
    });
    try {
      final result = await fetchWeather();
      setState(() {
        weather = result;
        weatherLoading = false;
      });
    } catch (e) {
      setState(() {
        weatherError = 'Could not load weather';
        weatherLoading = false;
      });
    }
  }

  Future<void> saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final list = courses.map((course) => course.toJson()).toList();
    await prefs.setString('my_courses', jsonEncode(list));
  }

  Future<void> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('my_courses');
    if (saved != null) {
      final list = jsonDecode(saved) as List;
      setState(() {
        courses = list.map((x) => Course.fromJson(x as Map<String, dynamic>)).toList();
      });
    } else {
      setState(() {
        courses = sampleCourses();
      });
    }
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<Course>(
      context,
      MaterialPageRoute(
        builder: (_) => EditCourseScreen(
          allCourses: courses,
          initialDay: selectedDay,
        ),
      ),
    );
    if (result != null) {
      setState(() => courses.add(result));
      saveCourses();
    }
  }

  Future<void> _openEdit(Course c) async {
    final action = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (_) => EditCourseScreen(
          allCourses: courses,
          existing: c,
        ),
      ),
    );
    if (action == null) return;

    if (action is Course) {
      setState(() {
        final i = courses.indexOf(c);
        courses[i] = action;
      });
      saveCourses();
    } else if (action == 'delete') {
      setState(() => courses.remove(c));
      saveCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final byDay = groupByDay(courses);
    final weekTotal = courses.fold(0, (s, c) => s + (c.end - c.start));
    final today = byDay[selectedDay] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('My Week · ${formatDuration(weekTotal)}'),
      ),
      body: Column(
        children: [
          // WEATHER WIDGET ADDED HERE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: weatherLoading
                ? const Center(child: CircularProgressIndicator())
                : weatherError != null
                ? Column(
              children: [
                Text(weatherError!, style: const TextStyle(color: Colors.red)),
                TextButton(
                  onPressed: loadWeather,
                  child: const Text('Retry'),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Kigali: ${weather!.temperature}°C',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // REST OF YOUR APP
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: days.map((d) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(d),
                  selected: selectedDay == d,
                  onSelected: (_) => setState(() => selectedDay = d),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: today.isEmpty
                ? Center(child: Text('No classes on $selectedDay'))
                : ListView.builder(
              itemCount: today.length,
              itemBuilder: (_, i) {
                final c = today[i];
                final conflicts = clashesWith(c, today);
                final hasClash = conflicts.isNotEmpty;

                return ListTile(
                  leading: Icon(
                    hasClash ? Icons.warning : Icons.book,
                    color: hasClash ? Colors.red : null,
                  ),
                  title: Text(
                    c.name,
                    style: TextStyle(color: hasClash ? Colors.red : null),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${formatTime(c.start)} – ${formatTime(c.end)}'),
                      if (hasClash)
                        Text(
                          'Clashes with ${conflicts.map((x) => x.name).join(', ')}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  onTap: () => _openEdit(c),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '$selectedDay total: ${formatDuration(dayTotalMinutes(today))}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}