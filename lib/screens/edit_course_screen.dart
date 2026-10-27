import 'package:flutter/material.dart';
import '../models/course.dart';
import '../logic/time_utils.dart';
import '../logic/course_rules.dart';

class EditCourseScreen extends StatefulWidget {
  final List<Course> allCourses;
  final Course? existing;
  final String? initialDay;

  const EditCourseScreen({
    super.key,
    required this.allCourses,
    this.existing,
    this.initialDay,
  });

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  late final TextEditingController _name;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late String _day;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name  = TextEditingController(text: c?.name ?? '');
    _start = TextEditingController(text: c != null ? formatTime(c.start) : '');
    _end   = TextEditingController(text: c != null ? formatTime(c.end)   : '');
    _day   = c?.day ?? widget.initialDay ?? 'Mon';
  }

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _save() {
    final err = validateCourse(
      name: _name.text,
      startRaw: _start.text,
      endRaw: _end.text,
      existing: widget.allCourses,
      editing: widget.existing,
    );
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final course = Course(
      name: _name.text.trim(),
      day: _day,
      start: parseTime(_start.text)!,
      end: parseTime(_end.text)!,
    );

    Navigator.pop(context, course);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this course?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context, 'delete');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Course' : 'Edit Course')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Course Name'),
          ),
          const SizedBox(height: 16),
          const Text('Day'),
          Wrap(
            spacing: 8,
            children: days.map((d) => ChoiceChip(
              label: Text(d),
              selected: _day == d,
              onSelected: (_) => setState(() => _day = d),
            )).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _start,
            decoration: const InputDecoration(labelText: 'Start Time (e.g. 08:00)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _end,
            decoration: const InputDecoration(labelText: 'End Time (e.g. 10:00)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _confirmDelete,
              child: const Text('Delete Course', style: TextStyle(color: Colors.red)),
            ),
          ]
        ],
      ),
    );
  }
}