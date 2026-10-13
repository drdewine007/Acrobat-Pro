
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
void main() {
WidgetsFlutterBinding.ensureInitialized();
runApp(const AcrobatProApp());
}
class AppThemePalette {
final String id;
final String name;
final Color bg;
final Color header;
final Color card;
final Color border;
final Color primary;
final Color primaryText;
final Color text;
final Color muted;
final bool isLight;
const AppThemePalette({
required this.id,
required this.name,
required this.bg,
required this.header,
required this.card,
required this.border,
required this.primary,
required this.primaryText,
required this.text,
required this.muted,
this.isLight = false,
});
}
const List<AppThemePalette> kThemes = [
AppThemePalette(
id: 'pixel',
name: 'Material Pixel',
bg: Color(0xFF111318),
header: Color(0xFF1B1E26),
card: Color(0xFF1E222B),
border: Color(0xFF2E3545),
primary: Color(0xFFA8C7FA),
primaryText: Color(0xFF062E6F),
text: Color(0xFFE2E2E9),
muted: Color(0xFF8E9099),
),
AppThemePalette(
id: 'cyberpunk',
name: 'Cyberpunk Neon',
bg: Color(0xFF090A14),
header: Color(0xFF121428),
card: Color(0xFF161932),
border: Color(0xFF383E78),
primary: Color(0xFF00F5D4),
primaryText: Color(0xFF051923),
text: Color(0xFFF8F9FA),
muted: Color(0xFF9D9EDD),
),
AppThemePalette(
id: 'academic',
name: 'Warm Academic',
bg: Color(0xFFF6F1E7),
header: Color(0xFFEAE2D3),
card: Color(0xFFFFFDF9),
border: Color(0xFFD8CEBE),
primary: Color(0xFF1F5E4B),
primaryText: Color(0xFFFFFFFF),
text: Color(0xFF231F1B),
muted: Color(0xFF6E655A),
isLight: true,
),
AppThemePalette(
id: 'crimson',
name: 'Crimson Velvet',
bg: Color(0xFF050507),
header: Color(0xFF120A0E),
card: Color(0xFF180E13),
border: Color(0xFF3B1C28),
primary: Color(0xFFFF4D6D),
primaryText: Color(0xFFFFFFFF),
text: Color(0xFFFFF0F3),
muted: Color(0xFFB5838D),
),
];
class AcrobatProApp extends StatefulWidget {
const AcrobatProApp({super.key});
@override
State<AcrobatProApp> createState() => _AcrobatProAppState();
}
class _AcrobatProAppState extends State<AcrobatProApp> {
AppThemePalette _currentTheme = kThemes[0];
@override
void initState() {
super.initState();
_loadTheme();
}
Future<void> _loadTheme() async {
final prefs = await SharedPreferences.getInstance();
final id = prefs.getString('app_theme_v6') ?? 'pixel';
final found = kThemes.where((t) => t.id == id).firstOrNull ?? kThemes[0];
if (mounted) setState(() => _currentTheme = found);
}
Future<void> _setTheme(AppThemePalette palette) async {
setState(() => _currentTheme = palette);
final prefs = await SharedPreferences.getInstance();
await prefs.setString('app_theme_v6', palette.id);
}
@override
Widget build(BuildContext context) {
final base = _currentTheme.isLight ? ThemeData.light() : ThemeData.dark();
return MaterialApp(
title: 'Acrobat Pro',
debugShowCheckedModeBanner: false,
theme: base.copyWith(
scaffoldBackgroundColor: _currentTheme.bg,
colorScheme: base.colorScheme.copyWith(
primary: _currentTheme.primary,
surface: _currentTheme.card,
),
),
home: HomeScreen(
palette: _currentTheme,
onThemeChanged: _setTheme,
),
);
}
}
class SavedPdfItem {
final String path;
final String name;
final int currentPage;
final int totalPages;
final int updatedAt;
final String? password;
SavedPdfItem({
required this.path,
required this.name,
required this.currentPage,
required this.totalPages,
required this.updatedAt,
this.password,
});
Map<String, dynamic> toJson() => {
'path': path,
'name': name,
'currentPage': currentPage,
'totalPages': totalPages,
'updatedAt': updatedAt,
'password': password,
};
factory SavedPdfItem.fromJson(Map<String, dynamic> json) => SavedPdfItem(
path: json['path'] as String,
name: json['name'] as String,
currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
password: json['password'] as String?,
);
}
class HomeScreen extends StatefulWidget {
final AppThemePalette palette;
final ValueChanged<AppThemePalette> onThemeChanged;
const HomeScreen({
super.key,
required this.palette,
required this.onThemeChanged,
});
@override
State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
List<SavedPdfItem> _recentItems = [];
static const String _prefsKey = 'recent_pdfs_v6';
@override
void initState() {
super.initState();
_loadRecentItems();
}
Future<void> _loadRecentItems() async {
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getStringList(prefsKey) ?? [];
final items = <SavedPdfItem>[];
for (final s in raw) {
try {
final item = SavedPdfItem.fromJson(jsonDecode(s));
if (File(item.path).existsSync()) {
items.add(item);
}
} catch () {}
}
items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
if (mounted) setState(() => _recentItems = items);
}
Future<void> _saveProgress(
String path, String name, int page, int total, String? password) async {
final prefs = await SharedPreferences.getInstance();
final existing = _recentItems.where((e) => e.path == path).firstOrNull;
final updated = SavedPdfItem(
path: path,
name: name,
currentPage: page,
totalPages: total,
updatedAt: DateTime.now().millisecondsSinceEpoch,
password: password ?? existing?.password,
);
final map = {for (var i in _recentItems) i.path: i};
map[path] = updated;
final list = map.values.toList()
..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
await prefs.setStringList(
_prefsKey,
list.map((e) => jsonEncode(e.toJson())).toList(),
);
await _loadRecentItems();
}
Future<void> _pickAndOpenPdf() async {
final result = await FilePicker.platform.pickFiles(
type: FileType.custom,
allowedExtensions: ['pdf'],
);
if (result == null || result.files.single.path == null) return;
final pickedFile = File(result.files.single.path!);
final fileName = result.files.single.name;
final appDir = await getApplicationDocumentsDirectory();
final savedPath = '${appDir.path}/$fileName';
if (pickedFile.path != savedPath) {
await pickedFile.copy(savedPath);
}
final existing = _recentItems.where((e) => e.path == savedPath).firstOrNull;
final initialPage = existing?.currentPage ?? 1;
if (!mounted) return;
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => PdfReaderScreen(
filePath: savedPath,
fileName: fileName,
initialPage: initialPage,
savedPassword: existing?.password,
palette: widget.palette,
onProgressChanged: (page, total, pwd) =>
_saveProgress(savedPath, fileName, page, total, pwd),
),
),
);
_loadRecentItems();
}
Future<void> _runOcrScan() async {
final picker = ImagePicker();
final image = await picker.pickImage(source: ImageSource.gallery);
if (image == null) return;
final recognizer = TextRecognizer();
final recognized = await recognizer.processImage(
InputImage.fromFilePath(image.path),
);
await recognizer.close();
if (!mounted)return;
showDialog(
context: context,
builder: (_) => AlertDialog(
title: const Text('OCR Extracted Text'),
content: SingleChildScrollView(
child: SelectableText(
recognized.text.isEmpty ? 'No text detected.' : recognized.text,
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('Close'),
),
],
),
);
}
void _showOverflowMenu(BuildContext context) {
final p = widget.palette;
showModalBottomSheet(
context: context,
backgroundColor: p.card,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
),
builder: (ctx) {
return SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(vertical: 12),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ListTile(
leading: Icon(Icons.share, color: p.text),
title: Text('Share App', style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
onTap: () {
Navigator.pop(ctx);
Share.share('Check out Acrobat Pro - The ultimate PDF Reader with auto-resume, password support, and themes!');
},
),
const Divider(),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
child: Text('SELECT THEME', style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.bold)),
),
...kThemes.map((t) => ListTile(
leading: Container(
width: 16,
height: 16,
decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
),
title: Text(t.name, style: TextStyle(color: p.text, fontWeight: t.id == p.id ? FontWeight.bold : FontWeight.normal)),
trailing: t.id == p.id ? Icon(Icons.check, color: p.primary) : null,
onTap: () {
Navigator.pop(ctx);
widget.onThemeChanged(t);
},
)),
],
),
),
);
},
);
}
@override
Widget build(BuildContext context) {
final p = widget.palette;
return Scaffold(
appBar: AppBar(
backgroundColor: p.header,
foregroundColor: p.text,
title: Row(
children: [
Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
decoration: BoxDecoration(
color: p.primary,
borderRadius: BorderRadius.circular(6),
),
child: Text(
'PDF',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w800,
color: p.primaryText,
),
),
),
const SizedBox(width: 10),
Text('Acrobat Pro',
style: TextStyle(fontWeight: FontWeight.bold, color: p.text)),
],
),
actions: [
IconButton(
icon: Icon(Icons.folder_open, color: p.primary),
onPressed: _pickAndOpenPdf,
tooltip: 'Open PDF',
),
IconButton(
icon: Icon(Icons.more_vert, color: p.text),
onPressed: () => _showOverflowMenu(context),
tooltip: 'More Options',
),
],
),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
Row(
children: [
Expanded(
child: ElevatedButton.icon(
style: ElevatedButton.styleFrom(
backgroundColor: p.primary,
foregroundColor: p.primaryText,
padding: const EdgeInsets.symmetric(vertical: 15),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
onPressed: _pickAndOpenPdf,
icon: const Icon(Icons.folder_open),
label: const Text(
'Open PDF',
style: TextStyle(fontWeight: FontWeight.bold),
),
),
),
const SizedBox(width: 12),
Expanded(
child: OutlinedButton.icon(
style: OutlinedButton.styleFrom(
foregroundColor: p.text,
padding: const EdgeInsets.symmetric(vertical: 15),
side: BorderSide(color: p.border),
backgroundColor: p.card,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
onPressed: _runOcrScan,
icon: const Icon(Icons.document_scanner_outlined),
label: const Text(
'OCR Scan',
style: TextStyle(fontWeight: FontWeight.bold),
),
),
),
],
),
const SizedBox(height: 24),
Text(
'Continue Reading (Auto-Resume)',
style: TextStyle(
fontSize: 14, fontWeight: FontWeight.bold, color: p.muted),
),
const SizedBox(height: 12),
if (_recentItems.isEmpty)
Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: p.card,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: p.border),
),
child: Text(
'No recent PDFs yet. Tap Open PDF to start reading.',
textAlign: TextAlign.center,
style: TextStyle(color: p.muted),
),
)
else
...recentItems.map((item) {
final pct = ((item.currentPage / item.totalPages) * 100)
.clamp(1, 100)
.round();
return Card(
color: p.card,
margin: const EdgeInsets.only(bottom: 12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
side: BorderSide(color: p.border),
),
child: ListTile(
contentPadding:
const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
title: Text(
'{item.name}{item.password != null ? " 🔒" : ""}',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style:
TextStyle(fontWeight: FontWeight.w600, color: p.text),
),
subtitle: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 4),
Text(
'Saved at Page ${item.currentPage} of ${item.totalPages} ($pct%)',
style: TextStyle(
color: p.primary,
fontSize: 12,
fontWeight: FontWeight.w600),
),
const SizedBox(height: 8),
LinearProgressIndicator(
value: item.currentPage / item.totalPages,
backgroundColor: p.border,
color: p.primary,
minHeight: 6,
borderRadius: BorderRadius.circular(3),
),
],
),
trailing: Text(
'Resume ▶',
style:
TextStyle(color: p.text, fontWeight: FontWeight.w600),
),
onTap: () async {
await Navigator.push(
context,
MaterialPageRoute(
builder: () => PdfReaderScreen(
filePath: item.path,
fileName: item.name,
initialPage: item.currentPage,
savedPassword: item.password,
palette: p,
onProgressChanged: (page, total, pwd) =>
_saveProgress(
item.path, item.name, page, total, pwd),
),
),
);
_loadRecentItems();
},
),
);
}),
],
),
);
}
}
class PdfReaderScreen extends StatefulWidget {
final String filePath;
final String fileName;
final int initialPage;
final String? savedPassword;
final AppThemePalette palette;
final void Function(int page, int total, String? password) onProgressChanged;
const PdfReaderScreen({
super.key,
required this.filePath,
required this.fileName,
required this.initialPage,
this.savedPassword,
required this.palette,
required this.onProgressChanged,
});
@override
State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}
class _PdfReaderScreenState extends State<PdfReaderScreen> {
final PdfViewerController _controller = PdfViewerController();
int _currentPage = 1;
int _totalPages = 1;
bool _nightMode = false;
String? _usedPassword;
bool _triedSavedPassword = false;
@override
void initState() {
super.initState();
_currentPage = widget.initialPage;
_usedPassword = widget.savedPassword;
}
Future<String?> _promptPasswordDialog() async {
if (!_triedSavedPassword && _usedPassword != null) {
_triedSavedPassword = true;
return _usedPassword;
}
final ctrl = TextEditingController();
final res = await showDialog<String>(
context: context,
barrierDismissible: false,
builder: (ctx) => AlertDialog(
title: const Text('🔒 Enter PDF Password'),
content: TextField(
controller: ctrl,
obscureText: true,
autofocus: true,
decoration: const InputDecoration(
hintText: 'Password',
border: OutlineInputBorder(),
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx, null),
child: const Text('Cancel'),
),
ElevatedButton(
onPressed: () => Navigator.pop(ctx, ctrl.text),
child: const Text('Unlock'),
),
],
),
);
_usedPassword = res;
return res;
}
@override
Widget build(BuildContext context) {
final p = widget.palette;
Widget viewer = PdfViewer.file(
widget.filePath,
controller: _controller,
initialPageNumber: widget.initialPage,
passwordProvider: _promptPasswordDialog,
params: PdfViewerParams(
backgroundColor: p.bg,
onViewerReady: (doc, controller) {
setState(() {
_totalPages = doc.pages.length;
});
widget.onProgressChanged(
_currentPage, doc.pages.length, _usedPassword);
},
onPageChanged: (pageNumber) {
if (pageNumber != null) {
setState(() => _currentPage = pageNumber);
widget.onProgressChanged(pageNumber, _totalPages, _usedPassword);
}
},
),
);
if (_nightMode) {
viewer = ColorFiltered(
colorFilter: const ColorFilter.matrix([
-1,  0,  0, 0, 255,
0, -1,  0, 0, 255,
0,  0, -1, 0, 255,
0,  0,  0, 1,   0,
]),
child: viewer,
);
}
return Scaffold(
appBar: AppBar(
backgroundColor: p.header,
foregroundColor: p.text,
title: Text(widget.fileName, style: const TextStyle(fontSize: 15)),
actions: [
Center(
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: p.card,
borderRadius: BorderRadius.circular(8),
border: Border.all(color: p.border),
),
child: Text(
'$_currentPage / $_totalPages',
style: TextStyle(
color: p.primary,
fontWeight: FontWeight.bold,
fontSize: 13,
),
),
),
),
IconButton(
icon: Icon(_nightMode ? Icons.light_mode : Icons.dark_mode),
onPressed: () => setState(() => _nightMode = !_nightMode),
tooltip: 'Toggle Dark Filter',
),
IconButton(
icon: const Icon(Icons.share),
onPressed: () => Share.share('Check out this PDF: ${widget.fileName}'),
tooltip: 'Share PDF',
),
],
),
body: viewer,
);
}
}
