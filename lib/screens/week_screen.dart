import 'package:flutter/material.dart';
import '../models/course.dart';
import '../data/sample_data.dart';
import '../logic/time_utils.dart';
import '../logic/course_rules.dart';
import 'edit_course_screen.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});
  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  final List<Course> courses = sampleCourses();
  String selectedDay = 'Mon';

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
    } else if (action == 'delete') {
      setState(() => courses.remove(c));
    }
  }

  @override
  Widget build(BuildContext context) {
    final byDay = groupByDay(courses);
    final weekTotal = courses.fold(0, (s, c) => s + (c.end - c.start));
    final today = byDay[selectedDay]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Week · ${formatDuration(weekTotal)}'),
      ),
      body: Column(
        children: [
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