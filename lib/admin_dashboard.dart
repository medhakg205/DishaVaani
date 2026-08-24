import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'models/poi.dart';
import 'services/poi_service.dart';

const _maroon = Color(0xFF6B2737);
const _terracotta = Color(0xFFC1652F);
const _sandstone = Color(0xFFF5EFE6);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _service = PoiService();
  final _formKey = GlobalKey<FormState>();
  final _monument = TextEditingController();
  final _name = TextEditingController();
  final _english = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  Poi? _editing;
  PlatformFile? _audioFile;
  bool _saving = false;
  double _heading = 0;
  double _tolerance = 25;

  @override
  void dispose() {
    for (final controller in [
      _monument,
      _name,
      _english,
      _latitude,
      _longitude,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _edit(Poi poi) {
    setState(() {
      _editing = poi;
      _monument.text = poi.monumentId;
      _name.text = poi.name;
      _english.text = poi.scriptText;
      _latitude.text = poi.lat.toString();
      _longitude.text = poi.long.toString();
      _heading = poi.compassHeading;
      _tolerance = poi.bearingTolerance;
      _audioFile = null;
    });
  }

  void _clear() {
    setState(() {
      _editing = null;
      _audioFile = null;
      _heading = 0;
      _tolerance = 25;
      for (final controller in [
        _monument,
        _name,
        _english,
        _latitude,
        _longitude,
      ]) {
        controller.clear();
      }
    });
  }

  Future<void> _chooseAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result != null && mounted)
      setState(() => _audioFile = result.files.single);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String audioUrl = _editing?.audioUrl ?? '';
      if (_audioFile != null) {
        audioUrl =
            (await _service.uploadAudio(
              file: _audioFile!,
              monumentId: _monument.text,
            )) ??
            audioUrl;
      }
      await _service.savePoi(
        id: _editing?.id,
        data: {
          'monumentId': _monument.text.trim().toLowerCase().replaceAll(
            ' ',
            '_',
          ),
          'name': _name.text.trim(),
          'scriptText': _english.text.trim(),
          'lat': double.parse(_latitude.text.trim()),
          'long': double.parse(_longitude.text.trim()),
          'compassHeading': _heading,
          'bearingTolerance': _tolerance,
          'audioUrl': audioUrl,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing == null
                ? 'POI published to Firebase.'
                : 'POI updated in Firebase.',
          ),
        ),
      );
      _clear();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Poi poi) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this POI?'),
        content: Text(
          '“${poi.name}” will be removed from Firestore. Its uploaded audio will remain in Storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (approved == true) {
      await _service.deletePoi(poi);
      if (_editing?.id == poi.id) _clear();
    }
  }

  String? _number(String? value, double min, double max, String label) {
    final number = double.tryParse(value ?? '');
    if (number == null || number < min || number > max)
      return '$label must be between $min and $max.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        title: const Text('DishaVaani Admin'),
        actions: [
          TextButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New POI', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<List<Poi>>(
        stream: _service.watchPois(),
        builder: (context, snapshot) {
          final list = snapshot.data ?? [];
          return LayoutBuilder(
            builder: (context, constraints) {
              final form = _buildForm();
              final records = _buildRecords(snapshot, list);
              if (constraints.maxWidth < 900) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [form, const SizedBox(height: 28), records],
                );
              }
              return Padding(
                padding: const EdgeInsets.all(28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(child: form),
                    ),
                    const SizedBox(width: 28),
                    Expanded(flex: 4, child: records),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildForm() => Card(
    color: Colors.white,
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing == null
                  ? 'Register a point of interest'
                  : 'Edit ${_editing!.name}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _maroon,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Publishing writes directly to the shared Firestore pois collection.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _field(_monument, 'Monument ID', hint: 'e.g. qutub_minar'),
            _field(_name, 'POI name'),
            _field(_english, 'English script / description', lines: 3),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _latitude,
                    'Latitude',
                    validator: (v) => _number(v, -90, 90, 'Latitude'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _longitude,
                    'Longitude',
                    validator: (v) => _number(v, -180, 180, 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Compass heading: ${_heading.round()}°',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _heading,
              max: 360,
              divisions: 360,
              activeColor: _terracotta,
              onChanged: (v) => setState(() => _heading = v),
            ),
            Text(
              'Bearing tolerance: ${_tolerance.round()}°',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _tolerance,
              min: 10,
              max: 45,
              divisions: 35,
              activeColor: _terracotta,
              onChanged: (v) => setState(() => _tolerance = v),
            ),
            OutlinedButton.icon(
              onPressed: _chooseAudio,
              icon: const Icon(Icons.audio_file),
              label: Text(
                _audioFile == null
                    ? (_editing?.audioUrl.isNotEmpty == true
                          ? 'Replace audio file'
                          : 'Upload audio file')
                    : _audioFile!.name,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _saving
                      ? 'Publishing…'
                      : _editing == null
                      ? 'Publish POI'
                      : 'Save changes',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _maroon,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int lines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      validator:
          validator ??
          (v) => (v == null || v.trim().isEmpty) ? '$label is required.' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _buildRecords(AsyncSnapshot<List<Poi>> snapshot, List<Poi> list) {
    if (snapshot.hasError)
      return const Center(
        child: Text(
          'Could not load Firestore records. Check your Firebase rules and web app configuration.',
        ),
      );
    if (!snapshot.hasData)
      return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Published POIs (${list.length})',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _maroon,
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No POIs yet. Use the form to publish the first one.',
              ),
            ),
          )
        else
          ...list.map(
            (poi) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _sandstone,
                  child: Icon(Icons.place, color: _terracotta),
                ),
                title: Text(poi.name),
                subtitle: Text(
                  '${poi.monumentId} · ${poi.lat.toStringAsFixed(4)}, ${poi.long.toStringAsFixed(4)}${poi.audioUrl.isNotEmpty ? ' · audio attached' : ''}',
                ),
                onTap: () => _edit(poi),
                trailing: IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _delete(poi),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
