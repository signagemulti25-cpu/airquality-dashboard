import 'dart:async';
import 'package:flutter/material.dart';
import '../models/air_quality_data.dart';
import '../services/air_quality_api.dart';
import 'package:airquality/widgets/display_header.dart';
import 'package:airquality/models/air_quality_location.dart';
import 'package:airquality/utils/air_quality_calculator.dart';

class AirQualityScreen extends StatefulWidget {
  final AirQualityLocation location;

  const AirQualityScreen({super.key, required this.location});

  @override
  State<AirQualityScreen> createState() => _AirQualityScreenState();
}

class _AirQualityScreenState extends State<AirQualityScreen> {
  final AirQualityApi api = AirQualityApi();

  // Initial/demo values.
  // These will be replaced by the API response.
  // AirQualityData data = AirQualityData(
  //   loggerId: '848',
  //   pm25: 13,
  //   pm10: 44,
  //   aqi: 50,
  //   updatedAt: DateTime(2026, 10, 6, 15, 23),
  // );
  late AirQualityData data;
  Timer? timer;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    data = AirQualityData(
      loggerId: widget.location.loggerId,
      pm25: 0,
      pm10: 0,
      aqi: 0,
      updatedAt: DateTime.now(),
    );

    loadData();

    // Fetch every 30 seconds.
    timer = Timer.periodic(const Duration(seconds: 30), (_) => loadData());
  }

  // Future<void> loadData() async {
  //   if (loading == false && !mounted) {
  //     return;
  //   }

  //   try {
  //     if (mounted) {
  //       setState(() {
  //         loading = true;
  //       });
  //     }

  //     final result = await api.fetchData(widget.location.loggerId);

  //     if (!mounted) return;

  //     setState(() {
  //       // IMPORTANT:
  //       // Replace the displayed data with API data.
  //       data = result;

  //       loading = false;
  //       error = null;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;

  //     setState(() {
  //       loading = false;
  //       error = e.toString();
  //     });
  //   }
  // }

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Fetch readings from the Cloudflare Worker.
      final allData = await api.fetchAllData();

      // Select the reading for this screen's logger.
      final result = allData[widget.location.loggerId];

      if (!mounted) return;

      if (result == null) {
        setState(() {
          loading = false;
          error =
              'No data available for logger '
              '${widget.location.loggerId}';
        });
        return;
      }

      setState(() {
        data = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget airQualityLevels() {
    const labels = [
      'GOOD',
      'SATISFACTORY',
      'MODERATE',
      'POOR',
      'VERY POOR',
      'SEVERE',
    ];

    const colors = [
      Color(0xFF00A651),
      Color(0xFF8BC34A),
      Color(0xFFFFC107),
      Color(0xFFFF9800),
      Color(0xFFF44336),
      Color(0xFF8B0000),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // Colored bars
          Row(
            children: List.generate(
              colors.length,
              (index) => Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 2,
                    right: index == colors.length - 1 ? 0 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Labels
          Row(
            children: List.generate(
              labels.length,
              (index) => Expanded(
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: colors[index],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _AirValueRow({
    required String label,
    required double value,
    required double scale,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 145 * scale,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 40 * scale,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: const Color(0xFF1D211E),
            ),
          ),
        ),

        SizedBox(width: 25 * scale),

        SizedBox(
          width: 105 * scale,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 40 * scale,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: const Color(0xFF1D211E),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = calculateAirQuality(aqi: data.aqi);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // Designed around your 1024 x 600 display,
            // but scales automatically.
            final scale = (width / 1024).clamp(0.75, 1.5);

            return Column(
              children: [
                // =====================================================
                // HEADER
                // =====================================================
                // Padding(
                //   padding: EdgeInsets.only(
                //     left: 28 * scale,
                //     right: 28 * scale,
                //     top: 22 * scale,
                //     bottom: 28 * scale,
                //   ),
                //   child: Row(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       // LEFT
                //       Expanded(
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             Text(
                //               'DLF DOWNTOWN PHASE 2',
                //               style: TextStyle(
                //                 fontSize: 30 * scale,
                //                 fontWeight: FontWeight.w700,
                //                 height: 1.05,
                //                 color: const Color(0xFF1D211E),
                //               ),
                //             ),

                //             SizedBox(height: 7 * scale),

                //             Text(
                //               'RealTime Air Quality',
                //               style: TextStyle(
                //                 fontSize: 22 * scale,
                //                 fontWeight: FontWeight.w400,
                //                 height: 1.0,
                //                 color: const Color(0xFF1D211E),
                //               ),
                //             ),

                //             SizedBox(height: 7 * scale),

                //             Text(
                //               'Last Updated: '
                //               '${formatDate(data.updatedAt)}',
                //               style: TextStyle(
                //                 fontSize: 12 * scale,
                //                 fontWeight: FontWeight.w400,
                //                 color: const Color(0xFF858585),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),

                //       // RIGHT
                //       Padding(
                //         padding: EdgeInsets.only(
                //           top: 4 * scale,
                //           right: 20 * scale,
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Text(
                //               'Powered By',
                //               style: TextStyle(
                //                 fontSize: 25 * scale,
                //                 fontWeight: FontWeight.w400,
                //                 color: const Color(0xFF1D211E),
                //               ),
                //             ),

                //             SizedBox(height: 5 * scale),

                //             Text(
                //               'AIrveda',
                //               style: TextStyle(
                //                 fontSize: 25 * scale,
                //                 fontWeight: FontWeight.w400,
                //                 color: const Color(0xFF1D211E),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                DisplayHeader(
                  location: widget.location.name,
                  updatedAt: data.updatedAt,
                ),
                // =====================================================
                // HEADER DIVIDER
                // =====================================================
                Container(
                  height: 1,
                  width: double.infinity,
                  color: const Color(0xFFD2D2D2),
                ),

                // =====================================================
                // MAIN CONTENT
                // =====================================================
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, -height * 0.025),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // -----------------------------
                          // PM2.5
                          // -----------------------------
                          AirQualityGauge(
                            pm25: data.pm25,
                            pm10: data.pm10,
                          
                          ),

                          SizedBox(height: 18 * scale),

                          // -----------------------------
                          // STATUS
                          // -----------------------------
                          Text(
                            status.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20 * scale,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                              color: const Color(0xFF1D211E),
                            ),
                          ),

                          SizedBox(height: 15 * scale),

                          Text(
                            status.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w400,
                              height: 1.0,
                              color: const Color(0xFF1D211E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // =====================================================
                // SMALL CONNECTION STATUS
                // =====================================================
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Cloud update unavailable',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                airQualityLevels(),
              ],
            );
          },
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class AirQualityRingPainter extends CustomPainter {
  final double pm25;
  final double pm10;
  final Color pm25Color;
  final Color pm10Color;
  final double rotation;

  AirQualityRingPainter({
    required this.pm25,
    required this.pm10,
    required this.pm25Color,
    required this.pm10Color,
    this.rotation = 180,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ==============================
    // OUTER RING = PM10
    // ==============================

    final outerRadius = size.width * 0.42;
    final startAngle = -2.35 + rotation;
    final outerBackground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD9D9D9);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      4.70,
      false,
      outerBackground,
    );

    final outerProgress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..color = pm10Color;

    final pm10Progress = (pm10 / 250.0).clamp(0.04, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      4.70 * pm10Progress,
      false,
      outerProgress,
    );

    // ==============================
    // INNER RING = PM2.5
    // ==============================

    final innerRadius = size.width * 0.28;

    final innerBackground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE4E4E4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      4.70,
      false,
      innerBackground,
    );

    final innerProgress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..color = pm25Color;

    final pm25Progress = (pm25 / 250.0).clamp(0.04, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      4.70 * pm25Progress,
      false,
      innerProgress,
    );
  }

  @override
  bool shouldRepaint(covariant AirQualityRingPainter oldDelegate) {
    return oldDelegate.pm25 != pm25 ||
        oldDelegate.pm10 != pm10 ||
        oldDelegate.pm25Color != pm25Color ||
        oldDelegate.pm10Color != pm10Color;
  }
}

class AirQualityGauge extends StatelessWidget {
  final double pm25;
  final double pm10;

  const AirQualityGauge({
    super.key,
    required this.pm25,
    required this.pm10,

  });

  Color getColor(double value) {
    if (value <= 50) {
      return const Color(0xFF20A83A);
    }

    if (value <= 100) {
      return const Color(0xFFE0B400);
    }

    if (value <= 150) {
      return const Color(0xFFFF8C00);
    }

    if (value <= 250) {
      return const Color(0xFFE53935);
    }

    return const Color(0xFF8E0000);
  }

  @override
  Widget build(BuildContext context) {
    const size = 330.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ==========================================
          // RINGS
          // ==========================================
          Positioned.fill(
            child: CustomPaint(
              painter: AirQualityRingPainter(
                pm25: pm25,
                pm10: pm10,
                pm25Color: getColor(pm25),
                pm10Color: getColor(pm10),
              ),
            ),
          ),
          // CENTER — AQI VALUE
        
          // ==========================================
          // PM10 — RING START / BOTTOM LEFT
          // ==========================================
          Positioned(
            left: 175,
            bottom: 5,
            child: Row(
              children: [
                Container(width: 30, height: 3, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  pm10.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202420),
                  ),
                ),
                SizedBox(width: 8),
                const Text(
                  'PM10',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,

                    color: Color(0xFF202420),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // OUTDOOR — RING END / BOTTOM RIGHT
          // ==========================================
          Positioned(
            right: 10,
            bottom: 110,
            child: Text(
              'OUTDOOR',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202420),
              ),
            ),
          ),

          // ==========================================
          // CENTER — PM2.5
          // ==========================================
          Positioned(
            left: 175,
            right: 0,
            top: 245,
            child: Row(
              children: [
                Container(width: 30, height: 3, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  pm25.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202420),
                  ),
                ),
                SizedBox(width: 8),
                const Text(
                  'PM2.5',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202420),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeValue extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double width;

  const _GaugeValue({
    required this.label,
    required this.value,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width * 0.13,
          height: width * 0.025,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        SizedBox(width: width * 0.035),

        SizedBox(
          width: width * 0.10,
          child: Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: width * 0.055,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF202420),
            ),
          ),
        ),

        SizedBox(
          width: width * 0.08,
          child: Text(
            label,
            style: TextStyle(
              fontSize: width * 0.038,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF202420),
            ),
          ),
        ),
      ],
    );
  }
}
