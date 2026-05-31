import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../detection/data/models/disease_recommendation_model.dart';
import '../../../history/data/models/history_item_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/sign_in_page.dart';

import '../../../detection/data/domain/disease_recommendation_data.dart';
import '../../../detection/data/models/detection_box_model.dart';
import '../../../detection/data/tflite/tflite_service.dart';
import '../widgets/detection_painter.dart';
import 'detection_result_page.dart';

class HomeDetectPage extends StatefulWidget {
  const HomeDetectPage({super.key});

  @override
  State<HomeDetectPage> createState() => _HomeDetectPageState();
}

class _HomeDetectPageState extends State<HomeDetectPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();
  final TfliteService _tflite = TfliteService();

  XFile? _pickedImage;
  List<DetectionBoxModel> _detections = [];
  bool _isDetecting = false;

  String _status = "No image selected";
  String _disease = "-";
  String _confidence = "-";

  Future<void> _pickFromCamera() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (img == null) return;

      setState(() {
        _pickedImage = img;
        _status = "Image selected (Camera)";
        _detections = [];
        _disease = "-";
        _confidence = "-";
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Camera error: $e")));
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (img == null) return;

      setState(() {
        _pickedImage = img;
        _status = "Image selected (Gallery)";
        _detections = [];
        _disease = "-";
        _confidence = "-";
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gallery error: $e")));
    }
  }

  void _openPickerSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Image Source",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text("Camera"),
                  subtitle: const Text("Take a photo"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text("Gallery"),
                  subtitle: const Text("Pick from gallery"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // save history to Hive
  Future<void> _saveHistory({
    required String imagePath,
    required String diseaseName,
    required double confidence,
    required DiseaseRecommendationModel? recommendation,
    required DetectionBoxModel detection,
  }) async {
    if (recommendation == null) return;

    final box = Hive.box<HistoryItemModel>('history_box');

    final item = HistoryItemModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imagePath: imagePath,
      diseaseName: diseaseName,
      confidence: confidence,
      createdAt: DateTime.now(),
      shortDescription: recommendation.shortDescription,
      recommendedMedicines: recommendation.recommendedMedicines,
      dosageGuide: recommendation.dosageGuide,
      precautions: recommendation.precautions,
      preventionTips: recommendation.preventionTips,

      boxLeft: detection.rect.left,
      boxTop: detection.rect.top,
      boxRight: detection.rect.right,
      boxBottom: detection.rect.bottom,
    );

    await box.add(item);
  }

  Future<void> _onDetectPressed() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select image first")),
      );
      return;
    }

    setState(() {
      _isDetecting = true;
      _status = "Detecting...";
      _detections = [];
      _disease = "-";
      _confidence = "-";
    });

    try {
      final detections = await _tflite.detectObjects(File(_pickedImage!.path));

      if (detections.isNotEmpty) {
        final first = detections.first;
        final recommendation = DiseaseRecommendationData.getByClassName(
          first.className,
        );

        setState(() {
          _isDetecting = false;
          _detections = detections;
          _disease = first.className;
          _confidence = first.confidence.toStringAsFixed(3);
          _status = "Disease detected";
        });

        await _saveHistory(
          imagePath: _pickedImage!.path,
          diseaseName: first.className,
          confidence: first.confidence,
          recommendation: recommendation,
          detection: first,
        );
      } else {
        setState(() {
          _isDetecting = false;
          _detections = [];
          _disease = "-";
          _confidence = "-";
          _status = "No disease detected";
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Model is not trained for this image"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDetecting = false;
        _detections = [];
        _disease = "-";
        _confidence = "-";
        _status = "Detection failed";
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Detection error: $e")));
    }
  }

  void _openDetails() {
    if (_detections.isEmpty || _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No data for this disease"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final recommendation = DiseaseRecommendationData.getByClassName(_disease);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetectionResultPage(
          imagePath: _pickedImage!.path,
          detections: _detections,
          recommendation: recommendation,
        ),
      ),
    );
  }

  void _logout() {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
  }

  void _openAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("CottonGuard AI"),
        content: const Text(
          "Cotton disease detection app.\n\nImage detection, bounding boxes, recommendation details.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _openHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("History screen next step (Hive)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SignInPage()),
            (_) => false,
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.eco_outlined),
                  title: Text(
                    "Menu",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text("CottonGuard AI"),
                ),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "History",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: 560,
                  child: ValueListenableBuilder<Box<HistoryItemModel>>(
                    valueListenable: Hive.box<HistoryItemModel>(
                      'history_box',
                    ).listenable(),
                    builder: (context, box, _) {
                      final items = box.values.toList().reversed.toList();

                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            "No history yet",
                            style: TextStyle(fontSize: 13),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          void openSavedDetail() {
                            Navigator.pop(context);

                            final savedRecommendation =
                                DiseaseRecommendationModel(
                                  diseaseName: item.diseaseName,
                                  shortDescription: item.shortDescription,
                                  recommendedMedicines:
                                      item.recommendedMedicines,
                                  dosageGuide: item.dosageGuide,
                                  precautions: item.precautions,
                                  preventionTips: item.preventionTips,
                                );

                            final savedDetection = DetectionBoxModel(
                              className: item.diseaseName,
                              confidence: item.confidence,
                              rect: Rect.fromLTRB(
                                item.boxLeft,
                                item.boxTop,
                                item.boxRight,
                                item.boxBottom,
                              ),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetectionResultPage(
                                  imagePath: item.imagePath,
                                  detections: [savedDetection],
                                  recommendation: savedRecommendation,
                                  animateText: false,
                                ),
                              ),
                            );
                          }

                          Future<void> confirmDelete() async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete History'),
                                content: Text(
                                  'Do you want to delete "${item.diseaseName}" from history?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Yes, Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete == true) {
                              await item.delete();

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.diseaseName} deleted'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          }

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 42,
                                height: 42,
                                child: File(item.imagePath).existsSync()
                                    ? Image.file(
                                        File(item.imagePath),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.black12,
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              item.diseaseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${(item.confidence * 100).toStringAsFixed(1)}% • ${DateFormat('dd MMM, hh:mm a').format(item.createdAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'open') {
                                  openSavedDetail();
                                }

                                if (value == 'delete') {
                                  confirmDelete();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem<String>(
                                  value: 'open',
                                  child: Text('Open'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                            onTap: openSavedDetail,
                          );
                        },
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("About"),
                  onTap: () {
                    Navigator.pop(context);
                    _openAbout();
                  },
                ),
                const Spacer(),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: _logout,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          title: const Text("CottonGuard AI"),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openPickerSheet,
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_outlined, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Detect cotton pests & diseases",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Select image from Camera/Gallery, then Detect.",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _PreviewBox(
                image: _pickedImage,
                isDetecting: _isDetecting,
                detections: _detections,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: "Disease",
                      value: _disease,
                      icon: Icons.bug_report_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: "Confidence",
                      value: _confidence,
                      icon: Icons.insights_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isDetecting ? null : _onDetectPressed,
                  icon: _isDetecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _isDetecting ? "Detecting..." : "Upload / Detect",
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openDetails,
                  icon: const Icon(Icons.article_outlined),
                  label: const Text("View Details"),
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "Tip: Tap + button below to select image from camera or gallery.",
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: _BottomBar(
          status: _status,
          disease: _disease,
          confidence: _confidence,
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final XFile? image;
  final bool isDetecting;
  final List<DetectionBoxModel> detections;

  const _PreviewBox({
    required this.image,
    required this.isDetecting,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? const Center(
              child: Text(
                "No Image Selected\nTap + to choose",
                textAlign: TextAlign.center,
              ),
            )
          : FutureBuilder<Size>(
              future: _loadImageSize(image!.path),
              builder: (context, snapshot) {
                final imageWidget = Image.file(
                  File(image!.path),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                );

                if (!snapshot.hasData) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      imageWidget,
                      if (isDetecting)
                        Container(
                          color: Colors.black.withOpacity(0.18),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    imageWidget,
                    CustomPaint(
                      painter: DetectionPainter(
                        detections: detections,
                        imageOriginalSize: snapshot.data!,
                        boxFit: BoxFit.contain,
                      ),
                    ),
                    if (isDetecting)
                      Container(
                        color: Colors.black.withOpacity(0.18),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Future<Size> _loadImageSize(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String status;
  final String disease;
  final String confidence;

  const _BottomBar({
    required this.status,
    required this.disease,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            if (disease != "-")
              Text(
                disease,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(width: 8),
            if (confidence != "-")
              Text(confidence, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
