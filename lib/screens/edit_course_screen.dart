import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../logic/time_utils.dart';
import '../logic/course_rules.dart';
import '../state/course_state.dart';

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

  File? _photo;
  bool _saving = false;

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

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 70,
    );
    if (picked == null) return;
    setState(() => _photo = File(picked.path));
  }

  Widget _photoPreview() {
    if (_photo != null) {
      return Image.file(_photo!, height: 180, fit: BoxFit.cover);
    }
    final saved = widget.existing?.photoUrl;
    if (saved != null) {
      return Image.network(
        saved,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
        const SizedBox(height: 180, child: Center(child: Icon(Icons.broken_image))),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _save() async {
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

    final brain = context.read<CourseState>();
    setState(() => _saving = true);

    try {
      String? photoUrl = widget.existing?.photoUrl;

      if (_photo != null) {
        photoUrl = await brain.uploadPhoto(_photo!);
      }

      final course = Course(
        id: widget.existing?.id ?? '',
        name: _name.text.trim(),
        day: _day,
        start: parseTime(_start.text)!,
        end: parseTime(_end.text)!,
        photoUrl: photoUrl,
      );

      if (mounted) Navigator.pop(context, course);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
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
    final weekTotal = context.watch<CourseState>().weekTotal;

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Course' : 'Edit Course')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Your week total: ${formatDuration(weekTotal)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

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

          _photoPreview(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('Save'),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _saving ? null : _confirmDelete,
              child: const Text('Delete Course', style: TextStyle(color: Colors.red)),
            ),
          ]
        ],
      ),
    );
  }
}