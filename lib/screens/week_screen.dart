import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String selectedDay = 'Mon';

  Weather? weather;
  bool weatherLoading = true;
  String? weatherError;

  @override
  void initState() {
    super.initState();
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

  Future<void> addSampleCourses() async {
    final samples = sampleCourses();
    final batch = FirebaseFirestore.instance.batch();
    for (final c in samples) {
      batch.set(myCourses().doc(), c.toMap());
    }
    await batch.commit();
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<Course>(
      context,
      MaterialPageRoute(
        builder: (_) => EditCourseScreen(
          allCourses: [],
          initialDay: selectedDay,
        ),
      ),
    );
    if (result != null) {
      await myCourses().add(result.toMap());
    }
  }

  Future<void> _openEdit(Course c) async {
    final action = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (_) => EditCourseScreen(
          allCourses: [],
          existing: c,
        ),
      ),
    );
    if (action == null) return;

    if (action is Course) {
      await myCourses().doc(c.id).update(action.toMap());
    } else if (action == 'delete') {
      await myCourses().doc(c.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Week'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
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
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: myCourses().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load your courses.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final courses = snapshot.data!.docs.map(Course.fromDoc).toList();

                if (courses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No courses yet!'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: addSampleCourses,
                          child: const Text('Load Sample Data'),
                        ),
                      ],
                    ),
                  );
                }

                final byDay = groupByDay(courses);
                final weekTotal = courses.fold(0, (s, c) => s + (c.end - c.start));
                final today = byDay[selectedDay] ?? [];

                return Column(
                  children: [
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
                        '$selectedDay total: ${formatDuration(dayTotalMinutes(today))} · Week: ${formatDuration(weekTotal)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                );
              },
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