import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/platform/google_maps_availability.dart';
import '../../domain/entities/activity_location.dart';

class ActivityLocationPreview extends StatelessWidget {
  final ActivityLocation location;
  final bool offline;
  const ActivityLocationPreview(
      {super.key, required this.location, this.offline = false});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!offline)
          FutureBuilder<bool>(
              future: GoogleMapsAvailability.isConfigured(),
              builder: (context, snapshot) => snapshot.data == true
                  ? SizedBox(
                      height: 180,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                      location.latitude, location.longitude),
                                  zoom: 16),
                              markers: {
                                Marker(
                                    markerId: const MarkerId('meeting'),
                                    position: LatLng(
                                        location.latitude, location.longitude))
                              },
                              myLocationButtonEnabled: false,
                              mapToolbarEnabled: false,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false)))
                  : const SizedBox.shrink()),
        Text(
            '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}'),
        if (offline)
          const Text('Saved meeting point. Map tiles require a connection.'),
        TextButton.icon(
            icon: const Icon(Icons.map_outlined),
            label: const Text('Open in Google Maps'),
            onPressed: () async {
              try {
                final opened = await launchUrl(location.mapsUrl,
                    mode: LaunchMode.externalApplication);
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Unable to open Google Maps.')));
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Unable to open Google Maps.')));
                }
              }
            }),
      ]);
}
