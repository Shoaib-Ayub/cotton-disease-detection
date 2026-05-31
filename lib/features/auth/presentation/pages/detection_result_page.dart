import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../detection/data/models/detection_box_model.dart';
import '../../../detection/data/models/disease_recommendation_model.dart';
import '../widgets/detection_painter.dart';

class DetectionResultPage extends StatefulWidget {
  final String imagePath;
  final List<DetectionBoxModel> detections;
  final DiseaseRecommendationModel? recommendation;
  final bool animateText;

  const DetectionResultPage({
    super.key,
    required this.imagePath,
    required this.detections,
    required this.recommendation,
    this.animateText = true,
  });

  @override
  State<DetectionResultPage> createState() => _DetectionResultPageState();
}

class _DetectionResultPageState extends State<DetectionResultPage> {
  final ScrollController _scrollController = ScrollController();

  String _summaryAnimated = '';
  String _descriptionAnimated = '';
  String _medicinesAnimated = '';
  String _dosageAnimated = '';
  String _precautionsAnimated = '';
  String _preventionAnimated = '';

  bool _showSummaryCard = false;
  bool _showAiSummaryCard = false;
  bool _showRecommendationCard = false;
  bool _showDescriptionSection = false;
  bool _showMedicinesSection = false;
  bool _showDosageSection = false;
  bool _showPrecautionsSection = false;
  bool _showPreventionSection = false;

  bool _cursorVisible = true;
  Timer? _cursorTimer;
  Timer? _typingTimer;

  @override
  @override
  void initState() {
    super.initState();

    if (widget.animateText) {
      _startCursorBlink();
      _startSequence();
    } else {
      _showAllContentInstantly();
    }
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 420), (timer) {
      if (!mounted) return;
      setState(() {
        _cursorVisible = !_cursorVisible;
      });
    });
  }

  void _showAllContentInstantly() {
    final recommendation = widget.recommendation;

    _summaryAnimated = _buildAiSummaryText();

    _showSummaryCard = true;
    _showAiSummaryCard = true;

    if (recommendation != null) {
      _showRecommendationCard = true;
      _showDescriptionSection = true;
      _showMedicinesSection = true;
      _showDosageSection = true;
      _showPrecautionsSection = true;
      _showPreventionSection = true;

      _descriptionAnimated = recommendation.shortDescription;
      _medicinesAnimated = _bullets(recommendation.recommendedMedicines);
      _dosageAnimated = recommendation.dosageGuide;
      _precautionsAnimated = _bullets(recommendation.precautions);
      _preventionAnimated = _bullets(recommendation.preventionTips);
    }
  }

  Future<void> _startSequence() async {
    if (!mounted) return;

    setState(() {
      _showSummaryCard = true;
    });

    await _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    setState(() {
      _showAiSummaryCard = true;
    });

    await _scrollToBottom();

    await _typeText(
      fullText: _buildAiSummaryText(),
      onUpdate: (value) async {
        if (!mounted) return;
        setState(() {
          _summaryAnimated = value;
        });
        await _scrollToBottom();
      },
    );

    await Future.delayed(const Duration(milliseconds: 250));

    if (widget.recommendation == null || !mounted) return;

    setState(() {
      _showRecommendationCard = true;
      _showDescriptionSection = true;
    });

    await _scrollToBottom();

    await _typeText(
      fullText: widget.recommendation!.shortDescription,
      onUpdate: (value) async {
        if (!mounted) return;
        setState(() {
          _descriptionAnimated = value;
        });
        await _scrollToBottom();
      },
    );

    await Future.delayed(const Duration(milliseconds: 220));

    if (!mounted) return;
    setState(() {
      _showMedicinesSection = true;
    });

    await _scrollToBottom();

    await _typeText(
      fullText: _bullets(widget.recommendation!.recommendedMedicines),
      onUpdate: (value) async {
        if (!mounted) return;
        setState(() {
          _medicinesAnimated = value;
        });
        await _scrollToBottom();
      },
    );

    await Future.delayed(const Duration(milliseconds: 220));

    if (!mounted) return;
    setState(() {
      _showDosageSection = true;
    });

    await _scrollToBottom();

    await _typeText(
      fullText: widget.recommendation!.dosageGuide,
      onUpdate: (value) async {
        if (!mounted) return;
        setState(() {
          _dosageAnimated = value;
        });
        await _scrollToBottom();
      },
    );

    await Future.delayed(const Duration(milliseconds: 220));

    if (!mounted) return;
    setState(() {
      _showPrecautionsSection = true;
    });

    await _scrollToBottom();

    await _typeText(
      fullText: _bullets(widget.recommendation!.precautions),
      onUpdate: (value) async {
        if (!mounted) return;
        setState(() {
          _precautionsAnimated = value;
        });
        await _scrollToBottom();
      },
    );

    await Future.delayed(const Duration(milliseconds: 220));

    if (!mounted) return;
    setState(() {
      _showPreventionSection = true;
    });

    await _scrollToBottom();

    await _typeText(
      fullText: _bullets(widget.recommendation!.preventionTips),
      onUpdate: (value) async {
        if (!mounted) return;
        setState(() {
          _preventionAnimated = value;
        });
        await _scrollToBottom();
      },
    );
  }

  Future<void> _typeText({
    required String fullText,
    required Future<void> Function(String value) onUpdate,
  }) async {
    final completer = Completer<void>();
    int index = 0;

    _typingTimer?.cancel();

    _typingTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }

      if (index < fullText.length) {
        index++;
        await onUpdate(fullText.substring(0, index));
      } else {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });

    await completer.future;
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 40));
    if (!mounted || !_scrollController.hasClients) return;

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  String _buildAiSummaryText() {
    final r = widget.recommendation;
    final top = widget.detections.isNotEmpty ? widget.detections.first : null;

    final disease = r?.diseaseName ?? top?.className ?? 'Unknown disease';
    final confidence = top != null
        ? '${(top.confidence * 100).toStringAsFixed(1)}%'
        : '-';
    final description =
        r?.shortDescription ?? 'No short description available.';
    final medicine = (r != null && r.recommendedMedicines.isNotEmpty)
        ? r.recommendedMedicines.first
        : 'recommended treatment';

    return 'Detected disease: $disease. Confidence: $confidence. '
        '$description Initial recommendation ke liye $medicine use ki ja sakti hai. '
        'Neeche detailed guidance di gayi hai.';
  }

  String _bullets(List<String> items) {
    return items.map((e) => '• $e').join('\n');
  }

  String _withCursor(String text, {required bool active}) {
    if (!widget.animateText) return text;
    if (!active) return text;
    return _cursorVisible ? '$text|' : '$text ';
  }

  @override
  Widget build(BuildContext context) {
    final topDetection = widget.detections.isNotEmpty
        ? widget.detections.first
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Detection Details')),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            _FadeInCard(
              show: true,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FutureBuilder<Size>(
                          future: _loadImageSize(widget.imagePath),
                          builder: (context, snapshot) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.contain,
                                ),
                                if (snapshot.hasData)
                                  CustomPaint(
                                    painter: DetectionPainter(
                                      detections: widget.detections,
                                      imageOriginalSize: snapshot.data!,
                                      boxFit: BoxFit.contain,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            _FadeInCard(
              show: _showSummaryCard,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detection Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SummaryRow(
                          label: 'Disease',
                          value: topDetection?.className ?? '-',
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Confidence',
                          value: topDetection != null
                              ? '${(topDetection.confidence * 100).toStringAsFixed(1)}%'
                              : '-',
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Total Detections',
                          value: widget.detections.length.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            _FadeInCard(
              show: _showAiSummaryCard,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome_outlined),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AI Short Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _withCursor(
                            _summaryAnimated,
                            active:
                                _showAiSummaryCard &&
                                _summaryAnimated.length <
                                    _buildAiSummaryText().length,
                          ),
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            _FadeInCard(
              show: _showRecommendationCard && widget.recommendation != null,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.medical_services_outlined,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.recommendation?.diseaseName ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_showDescriptionSection) ...[
                          const SizedBox(height: 14),
                          const _SectionTitle(title: "Short Description"),
                          const SizedBox(height: 6),
                          Text(
                            _withCursor(
                              _descriptionAnimated,
                              active:
                                  _showDescriptionSection &&
                                  _showMedicinesSection == false,
                            ),
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ],

                        if (_showMedicinesSection) ...[
                          const SizedBox(height: 14),
                          const _SectionTitle(title: "Recommended Medicines"),
                          const SizedBox(height: 6),
                          Text(
                            _withCursor(
                              _medicinesAnimated,
                              active:
                                  _showMedicinesSection &&
                                  _showDosageSection == false,
                            ),
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ],

                        if (_showDosageSection) ...[
                          const SizedBox(height: 14),
                          const _SectionTitle(title: "Dosage Guide"),
                          const SizedBox(height: 6),
                          Text(
                            _withCursor(
                              _dosageAnimated,
                              active:
                                  _showDosageSection &&
                                  _showPrecautionsSection == false,
                            ),
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ],

                        if (_showPrecautionsSection) ...[
                          const SizedBox(height: 14),
                          const _SectionTitle(title: "Precautions"),
                          const SizedBox(height: 6),
                          Text(
                            _withCursor(
                              _precautionsAnimated,
                              active:
                                  _showPrecautionsSection &&
                                  _showPreventionSection == false,
                            ),
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ],

                        if (_showPreventionSection) ...[
                          const SizedBox(height: 14),
                          const _SectionTitle(title: "Prevention Tips"),
                          const SizedBox(height: 6),
                          Text(
                            _withCursor(
                              _preventionAnimated,
                              active: _showPreventionSection,
                            ),
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

class _FadeInCard extends StatelessWidget {
  final bool show;
  final Widget child;

  const _FadeInCard({required this.show, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      child: AnimatedSlide(
        offset: show ? Offset.zero : const Offset(0, 0.05),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        child: show ? child : const SizedBox.shrink(),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}
