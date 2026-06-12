import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../controller/home_controller.dart';
import '../model/location.dart';

class MapPage extends StatefulWidget {
  final HomeController controller;
  final ValueChanged<SushiLocation> onStartSession;

  const MapPage({
    super.key,
    required this.controller,
    required this.onStartSession,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<List<SushiLocation>> _locationsFuture = widget.controller
      .fetchLocations();
  SushiLocation? _selected;

  Future<void> _refresh() async {
    final nextLocations = widget.controller.fetchLocations();
    setState(() {
      _locationsFuture = nextLocations;
    });
    await nextLocations;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SushiLocation>>(
      future: _locationsFuture,
      builder: (context, snapshot) {
        final locations = snapshot.data ?? const <SushiLocation>[];
        final mappedLocations = locations
            .where((location) => location.hasCoordinates)
            .toList();

        return Column(
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _LocationMap(
                  locations: mappedLocations,
                  selected: _selected,
                  onSelected: (location) {
                    setState(() => _selected = location);
                  },
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: _LocationsPanel(
                loading: snapshot.connectionState == ConnectionState.waiting,
                error: snapshot.error,
                locations: locations,
                selected: _selected,
                onRefresh: _refresh,
                onSelected: (location) {
                  setState(() => _selected = location);
                },
                onStartSession: widget.onStartSession,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LocationMap extends StatelessWidget {
  static const _defaultCenter = LatLng(43.6532, -79.3832);

  final List<SushiLocation> locations;
  final SushiLocation? selected;
  final ValueChanged<SushiLocation> onSelected;

  const _LocationMap({
    required this.locations,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: locations.isEmpty ? 12 : 13,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sushi_social',
              ),
              MarkerLayer(
                markers: [
                  for (final location in locations)
                    Marker(
                      point: LatLng(location.latitude!, location.longitude!),
                      width: 44,
                      height: 44,
                      child: _LocationMarker(
                        selected: selected?.id == location.id,
                        onTap: () => onSelected(location),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.map_outlined, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Sushi locations')),
                  ],
                ),
              ),
            ),
          ),
          if (locations.isEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No mapped locations yet. Add latitude and longitude to locations in Supabase to show pins here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  LatLng get _center {
    final selectedLocation = selected;
    if (selectedLocation?.hasCoordinates == true) {
      return LatLng(selectedLocation!.latitude!, selectedLocation.longitude!);
    }
    if (locations.isNotEmpty) {
      return LatLng(locations.first.latitude!, locations.first.longitude!);
    }
    return _defaultCenter;
  }
}

class _LocationMarker extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _LocationMarker({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Sushi location',
      child: IconButton.filled(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: selected ? colors.primary : colors.surface,
          foregroundColor: selected ? colors.onPrimary : colors.primary,
          side: BorderSide(color: colors.primary, width: 2),
        ),
        icon: const Icon(Icons.restaurant),
      ),
    );
  }
}

class _LocationsPanel extends StatelessWidget {
  final bool loading;
  final Object? error;
  final List<SushiLocation> locations;
  final SushiLocation? selected;
  final Future<void> Function() onRefresh;
  final ValueChanged<SushiLocation> onSelected;
  final ValueChanged<SushiLocation> onStartSession;

  const _LocationsPanel({
    required this.loading,
    required this.error,
    required this.locations,
    required this.selected,
    required this.onRefresh,
    required this.onSelected,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRefresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (locations.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          children: const [
            SizedBox(height: 32),
            Icon(Icons.location_off_outlined, size: 44),
            SizedBox(height: 12),
            Text(
              'No locations yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'The database is ready. Locations added in Supabase will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: locations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final location = locations[index];
          return _LocationTile(
            location: location,
            selected: selected?.id == location.id,
            onTap: () => onSelected(location),
            onStart: () => onStartSession(location),
          );
        },
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final SushiLocation location;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const _LocationTile({
    required this.location,
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
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colors.surface,
          child: const Icon(Icons.set_meal),
        ),
        title: Text(
          location.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            location.subtitle,
            if (location.rating != null)
              '${location.rating} stars'
                  '${location.userRatingCount == null ? '' : ' (${location.userRatingCount})'}',
            if (!location.hasCoordinates) 'Coordinates missing',
          ].join('\n'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton.filled(
          tooltip: 'Start session',
          onPressed: onStart,
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
