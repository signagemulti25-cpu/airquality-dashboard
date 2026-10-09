import 'package:flutter/material.dart';


class DisplayHeader extends StatelessWidget {
  final String location;
  final DateTime updatedAt;

  const DisplayHeader({
    super.key,
    required this.location,
    required this.updatedAt,
  });

  String _time() {
    final h = updatedAt.hour == 0
        ? 12
        : (updatedAt.hour > 12 ? updatedAt.hour - 12 : updatedAt.hour);

    final minute = updatedAt.minute.toString().padLeft(2, '0');

    final suffix = updatedAt.hour >= 12 ? 'PM' : 'AM';

    return '$h:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 34, 12),
      child: Row(
        children: [
          // --------------------------------
          // BACK BUTTON
          // --------------------------------
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, size: 28),
          ),

          const SizedBox(width: 8),

          // --------------------------------
          // ECO ICON
          // --------------------------------
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 32),
          ),

          const SizedBox(width: 22),

          // --------------------------------
          // LOCATION DETAILS
          // --------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'RealTime Air Quality',
                  style: TextStyle(fontSize: 17),
                ),

                const SizedBox(height: 2),

                Text(
                  'Last Updated: Today, ${_time()}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // --------------------------------
          // POWERED BY
          // --------------------------------
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, color: Colors.green, size: 34),

              SizedBox(width: 8),

              Text(
                'Powered By\nAir Quality',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),

          const SizedBox(width: 18),

          // --------------------------------
          // SETTINGS BUTTON
          // --------------------------------
       
        ],
      ),
    );
  }
}
