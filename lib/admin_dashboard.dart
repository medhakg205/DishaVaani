import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'models/poi.dart';
import 'services/poi_service.dart';

const _maroon = Color(0xFF6B2638);
const _terracotta = Color(0xFFC86B32);
const _sandstone = Color(0xFFF9EEE6);
const _indiaGreen = Color(0xFF2E7D5B);
const _portalBackground = Color(0xFFF7F0E7);

class _GovtPortalHeader extends StatelessWidget {
  final String? monumentId;
  final bool isSaving;
  final VoidCallback onImport;
  final VoidCallback? onBack;
  final VoidCallback? onNewPoi;

  const _GovtPortalHeader({
    required this.monumentId,
    required this.isSaving,
    required this.onImport,
    this.onBack,
    this.onNewPoi,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_terracotta, Colors.white, _indiaGreen],
              ),
            ),
          ),
          Container(
            color: _maroon,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 9),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.white, size: 17),
                const SizedBox(width: 8),
                const Text(
                  'Government of India',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Skip to main content',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 18),
                const Text(
                  'A−   A   A+',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 18),
                const Icon(Icons.language, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Text('English', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            child: Row(
              children: [
                const Icon(Icons.account_balance, size: 48, color: _maroon),
                const SizedBox(width: 16),
                Container(width: 1, height: 50, color: Colors.black26),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ministry of Tourism',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'DishaVaani Administration Portal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _maroon,
                        ),
                      ),
                      Text(
                        'Digital heritage interpretation management system',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_user, color: _indiaGreen, size: 34),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE3E7E5)),
                bottom: BorderSide(color: Color(0xFFE3E7E5)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: [
                if (onBack != null)
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('All monuments'),
                  )
                else
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: _indiaGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(width: 26),
                const Text(
                  'Monuments',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 26),
                Text(
                  monumentId == null ? 'Administration' : 'POIs · $monumentId',
                  style: const TextStyle(color: Colors.black54),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onImport,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import data'),
                ),
                if (onNewPoi != null) ...[
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: onNewPoi,
                    style: FilledButton.styleFrom(backgroundColor: _indiaGreen),
                    icon: const Icon(Icons.add),
                    label: const Text('Add POI'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportHelp extends StatelessWidget {
  const _ImportHelp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _sandstone,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Bulk import: choose a CSV or XLSX file from the button above. '
        'Use columns monumentId, name, scriptText, latitude, longitude, and '
        'optional audioUrl.',
        style: TextStyle(fontSize: 13),
      ),
    );
  }
}

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
  String? _selectedMonumentId;

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
      _name.text = poi.name;
      _english.text = poi.scriptText;
      _latitude.text = poi.lat.toString();
      _longitude.text = poi.long.toString();
      _audioFile = null;
    });
  }

  void _clear() {
    setState(() {
      _editing = null;
      _audioFile = null;
      for (final controller in [_name, _english, _latitude, _longitude]) {
        controller.clear();
      }
    });
  }

  void _openMonument(String value) {
    final monumentId = Poi.normalizeMonumentId(value);
    if (monumentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a monument ID first.')),
      );
      return;
    }
    setState(() {
      _selectedMonumentId = monumentId;
      _monument.text = monumentId;
    });
    _clear();
  }

  void _backToMonuments() {
    _clear();
    setState(() => _selectedMonumentId = null);
  }

  Future<void> _chooseAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result != null && mounted)
      setState(() => _audioFile = result.files.single);
  }

  Future<void> _importDataset() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final rows = _readDataset(result.files.single);
      var imported = 0;
      final errors = <String>[];
      for (var index = 0; index < rows.length; index++) {
        try {
          final data = _datasetPoiData(rows[index]);
          await _service.savePoi(data: data);
          imported++;
        } catch (error) {
          errors.add('Row ${index + 2}: $error');
        }
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import complete'),
          content: Text(
            '$imported POI${imported == 1 ? '' : 's'} added.'
            '${errors.isEmpty ? '' : '\n\n${errors.length} row(s) skipped:\n${errors.take(5).join('\n')}'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not import this file: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, String>> _readDataset(PlatformFile file) {
    final bytes = file.bytes;
    if (bytes == null) throw StateError('The selected file could not be read.');
    final extension = (file.extension ?? '').toLowerCase();
    final List<List<String>> table;
    if (extension == 'csv') {
      table = const CsvToListConverter(shouldParseNumbers: false)
          .convert(utf8.decode(bytes, allowMalformed: true))
          .map(
            (row) => row.map((cell) => cell?.toString().trim() ?? '').toList(),
          )
          .toList();
    } else if (extension == 'xlsx') {
      final workbook = Excel.decodeBytes(bytes);
      if (workbook.tables.isEmpty)
        throw StateError('The Excel file has no sheets.');
      final sheet = workbook.tables.values.first;
      table = sheet.rows
          .map((row) => row.map(_excelCellText).toList())
          .toList();
    } else {
      throw StateError('Please select a CSV or XLSX file.');
    }
    if (table.length < 2)
      throw StateError('Add a header row and at least one POI row.');
    final headers = table.first.map(_normaliseHeader).toList();
    return table.skip(1).where((row) => row.any((cell) => cell.isNotEmpty)).map(
      (row) {
        return Map<String, String>.fromIterables(
          headers,
          List<String>.generate(
            headers.length,
            (i) => i < row.length ? row[i] : '',
          ),
        );
      },
    ).toList();
  }

  String _excelCellText(dynamic cell) {
    final value = cell?.value;
    return switch (value) {
      TextCellValue(:final value) => value.toString().trim(),
      IntCellValue(:final value) => value.toString(),
      DoubleCellValue(:final value) => value.toString(),
      BoolCellValue(:final value) => value.toString(),
      _ => value?.toString().trim() ?? '',
    };
  }

  Map<String, dynamic> _datasetPoiData(Map<String, String> row) {
    String value(List<String> keys) => keys
        .map((key) => row[key] ?? '')
        .firstWhere((item) => item.trim().isNotEmpty, orElse: () => '');
    final monumentId = value(['monumentid', 'monument', 'site']);
    final name = value(['name', 'poiname', 'title']);
    final script = value([
      'scripttext',
      'script',
      'description',
      'englishscript',
    ]);
    final latitude = double.tryParse(value(['lat', 'latitude']));
    final longitude = double.tryParse(value(['long', 'lng', 'longitude']));
    if (monumentId.trim().isEmpty ||
        name.trim().isEmpty ||
        script.trim().isEmpty) {
      throw StateError('monumentId, name, and scriptText are required.');
    }
    if (latitude == null || latitude < -90 || latitude > 90) {
      throw StateError('latitude must be between -90 and 90.');
    }
    if (longitude == null || longitude < -180 || longitude > 180) {
      throw StateError('longitude must be between -180 and 180.');
    }
    return {
      'monumentId': monumentId,
      'name': name,
      'scriptText': script,
      'lat': latitude,
      'long': longitude,
      'audioUrl': value(['audiourl', 'audio']),
    };
  }

  String _normaliseHeader(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String audioUrl = _editing?.audioUrl ?? '';
      if (_audioFile != null) {
        audioUrl =
            (await _service.uploadAudio(
              file: _audioFile!,
              monumentId: _selectedMonumentId!,
            )) ??
            audioUrl;
      }
      await _service.savePoi(
        id: _editing?.id,
        data: {
          'monumentId': _selectedMonumentId!,
          'name': _name.text.trim(),
          'scriptText': _english.text.trim(),
          'lat': double.parse(_latitude.text.trim()),
          'long': double.parse(_longitude.text.trim()),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $error')));
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
      backgroundColor: _portalBackground,
      body: Column(
        children: [
          _GovtPortalHeader(
            monumentId: _selectedMonumentId,
            isSaving: _saving,
            onImport: _importDataset,
            onBack: _selectedMonumentId == null ? null : _backToMonuments,
            onNewPoi: _selectedMonumentId == null ? null : _clear,
          ),
          Expanded(
            child: StreamBuilder<List<Poi>>(
              stream: _service.watchPois(),
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                if (_selectedMonumentId == null) {
                  return _buildMonuments(snapshot, list);
                }
                final monumentPois = list
                    .where((poi) => poi.monumentId == _selectedMonumentId)
                    .toList();
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final form = _buildForm();
                    final records = _buildRecords(snapshot, monumentPois);
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
          ),
        ],
      ),
    );
  }

  Widget _buildMonuments(AsyncSnapshot<List<Poi>> snapshot, List<Poi> pois) {
    if (snapshot.hasError) {
      return const Center(
        child: Text(
          'Could not load Firestore records. Check your Firebase rules and web app configuration.',
        ),
      );
    }
    if (!snapshot.hasData)
      return const Center(child: CircularProgressIndicator());

    final counts = <String, int>{};
    for (final poi in pois) {
      counts[poi.monumentId] = (counts[poi.monumentId] ?? 0) + 1;
    }
    final monumentIds = counts.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const Text(
          'Monuments',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _maroon,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a monument to manage its POIs, or enter a new monument ID to create it.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _monument,
                    onSubmitted: _openMonument,
                    decoration: const InputDecoration(
                      labelText: 'Monument ID',
                      hintText: 'e.g. qutub_minar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _openMonument(_monument.text),
                  style: FilledButton.styleFrom(backgroundColor: _maroon),
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _ImportHelp(),
        const SizedBox(height: 24),
        Text(
          'Existing monuments (${monumentIds.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (monumentIds.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No monuments yet. Create one above or import a dataset.',
              ),
            ),
          )
        else
          ...monumentIds.map(
            (id) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _sandstone,
                  child: Icon(Icons.account_balance, color: _terracotta),
                ),
                title: Text(id),
                subtitle: Text(
                  '${counts[id]} POI${counts[id] == 1 ? '' : 's'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openMonument(id),
              ),
            ),
          ),
      ],
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
