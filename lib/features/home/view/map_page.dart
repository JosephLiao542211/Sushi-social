import 'package:flutter/material.dart';

import '../model/sushi_place.dart';

class MapPage extends StatefulWidget {
  final ValueChanged<SushiPlace> onStartSession;

  const MapPage({super.key, required this.onStartSession});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  SushiPlace _selected = sushiPlaces.first;

  void _selectPlace(SushiPlace place) {
    setState(() => _selected = place);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _MapCanvas(selected: _selected, onSelected: _selectPlace),
          ),
        ),
        Expanded(
          flex: 4,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: sushiPlaces.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final place = sushiPlaces[index];
              return _PlaceTile(
                place: place,
                selected: place == _selected,
                onTap: () => _selectPlace(place),
                onStart: () => widget.onStartSession(place),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MapCanvas extends StatelessWidget {
  final SushiPlace selected;
  final ValueChanged<SushiPlace> onSelected;

  const _MapCanvas({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPainter(
                land: colors.surfaceContainerHighest,
                road: colors.outlineVariant,
                water: colors.tertiaryContainer,
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            right: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Nearby sushi places')),
                    Icon(Icons.tune, size: 18),
                  ],
                ),
              ),
            ),
          ),
          for (final place in sushiPlaces)
            Positioned(
              left: 24 + place.x * 260,
              top: 64 + place.y * 220,
              child: _MapPin(
                place: place,
                selected: place == selected,
                onTap: () => onSelected(place),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final SushiPlace place;
  final bool selected;
  final VoidCallback onTap;

  const _MapPin({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: place.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: selected ? 44 : 36,
          width: selected ? 44 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? colors.primary : colors.surface,
            border: Border.all(color: colors.primary, width: 2),
            boxShadow: const [
              BoxShadow(
                blurRadius: 12,
                color: Color(0x33000000),
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.restaurant,
            color: selected ? colors.onPrimary : colors.primary,
            size: selected ? 22 : 18,
          ),
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final SushiPlace place;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const _PlaceTile({
    required this.place,
    required this.selected,
    required this.onTap,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: selected
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.surface,
                child: const Icon(Icons.set_meal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${place.area}  ${place.distance}  ${place.price}  ${place.rating}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Top: ${place.topEater} with ${place.topRecord} plates',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${place.activeSessions}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('live', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Start session',
                onPressed: onStart,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Color land;
  final Color road;
  final Color water;

  const _MapPainter({
    required this.land,
    required this.road,
    required this.water,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = land);

    final waterPath = Path()
      ..moveTo(size.width * .78, 0)
      ..quadraticBezierTo(size.width * .92, size.height * .28, size.width, .0)
      ..lineTo(size.width, size.height)
      ..quadraticBezierTo(
        size.width * .80,
        size.height * .78,
        size.width * .86,
        size.height,
      )
      ..close();
    canvas.drawPath(waterPath, Paint()..color = water);

    final roadPaint = Paint()
      ..color = road
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .08, size.height * .25),
      Offset(size.width * .88, size.height * .48),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * .18, size.height * .86),
      Offset(size.width * .72, size.height * .08),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * .02, size.height * .62),
      Offset(size.width * .76, size.height * .72),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.land != land ||
        oldDelegate.road != road ||
        oldDelegate.water != water;
  }
}
