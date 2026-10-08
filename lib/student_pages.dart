import 'dart:typed_data';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'incident_page.dart';
import 'incident_tile.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

// --------------------------------------------------------------- student ----
class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.incidents;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 76,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  textStyle:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportPage())),
                icon: const Icon(Icons.warning_amber_rounded, size: 30),
                label: const Text('Report emergency'),
              ),
            ),
            const SizedBox(height: 20),
            Text('Your reports', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                    'No reports yet. In an emergency, tap Report emergency.'),
              ),
            for (final i in list) IncidentTile(i: i),
          ],
        );
      },
    );
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  Category cat = Category.medical;
  Place place = places[3];
  int people = 1;
  Uint8List? photo; // bytes of the attached photo (null = none)
  final desc = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    desc.dispose();
    super.dispose();
  }

  bool get _isMobileApp =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _pickPhoto() async {
    ImageSource? source = ImageSource.gallery;
    // Phones can use the camera. Web and desktop use the file chooser.
    if (_isMobileApp) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(sheet, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheet, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    }
    if (source == null) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (file == null) return; // user cancelled
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => photo = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not attach the photo. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _send() {
    final i = store.report(cat, place, people, desc.text, photo);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => IncidentPage(id: i.id)));
  }

  Widget _photoSection() {
    if (photo == null) {
      return OutlinedButton.icon(
        onPressed: _pickPhoto,
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Attach photo'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            photo!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 6),
          const Text('Photo attached'),
          const Spacer(),
          TextButton(onPressed: _pickPhoto, child: const Text('Replace')),
          TextButton(
            onPressed: () => setState(() => photo = null),
            child: const Text('Remove'),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New emergency report')),
      body: Backdrop(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('What happened?', style: t.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in Category.values)
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 18),
                      label: Text(c.label),
                      selected: cat == c,
                      onSelected: (_) => setState(() => cat = c),
                    ),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  const Icon(Icons.my_location, size: 18),
                  const SizedBox(width: 6),
                  Text('Where are you? (GPS fix is simulated)',
                      style: t.titleMedium),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in places)
                    ChoiceChip(
                      label: Text(p.name),
                      selected: place == p,
                      onSelected: (_) => setState(() => place = p),
                    ),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Text('People affected', style: t.titleMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: people > 1 ? () => setState(() => people--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$people', style: t.titleMedium),
                  IconButton(
                    onPressed: () => setState(() => people++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'For example: student unconscious and bleeding',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _photoSection(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    label: const Text('Send report'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
