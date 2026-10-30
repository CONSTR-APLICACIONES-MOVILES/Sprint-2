import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/repositories/places_source.dart';
import '../../domain/entities/activity_location.dart';

class LocationPickerView extends StatefulWidget {
  final ActivityLocation? initial;
  final PlacesSource source;
  final Widget Function(LatLng center, ValueChanged<LatLng> onPin)? mapBuilder;
  const LocationPickerView(
      {super.key, this.initial, required this.source, this.mapBuilder});
  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  final _search = TextEditingController();
  final _session =
      List.generate(24, (_) => Random.secure().nextInt(16).toRadixString(16))
          .join();
  late final Future<bool> _configured = widget.source.isConfigured();
  late ActivityLocation? _selection = widget.initial;
  late LatLng _center = LatLng(widget.initial?.latitude ?? 4.60971,
      widget.initial?.longitude ?? -74.08175);
  GoogleMapController? _map;
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  String? _error;
  int _generation = 0;
  void _query(String query) {
    _debounce?.cancel();
    final generation = ++_generation;
    setState(() {
      _suggestions = [];
      _error = null;
      _loading = false;
    });
    if (query.trim().length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final rows = await widget.source.search(
            query.trim(), _session, _center.latitude, _center.longitude);
        if (mounted && generation == _generation) {
          setState(() {
            _suggestions = rows;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted && generation == _generation) {
          setState(() {
            _loading = false;
            _error =
                'Unable to search places. Try again or choose a pin on the map.';
          });
        }
      }
    });
  }

  Future<void> _choose(PlaceSuggestion suggestion) async {
    _debounce?.cancel();
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final selected = await widget.source.details(suggestion.id, _session);
      if (!mounted || generation != _generation) return;
      setState(() {
        _selection = selected;
        _center = LatLng(selected.latitude, selected.longitude);
        _suggestions = [];
        _loading = false;
      });
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_center, 16));
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = 'This place could not be loaded. Try another result.';
        });
      }
    }
  }

  void _pin(LatLng point) {
    _debounce?.cancel();
    _generation++;
    setState(() {
      _center = point;
      _suggestions = [];
      _loading = false;
      _error = null;
      _selection = ActivityLocation(
          latitude: point.latitude,
          longitude: point.longitude,
          label:
              'Pinned location (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _map?.dispose();
    unawaited(widget.source.endSession(_session).catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Choose location')),
      body: FutureBuilder<bool>(
          future: _configured,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data != true) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                          'Maps are unavailable in this build. Go back and enter the meeting place manually.')));
            }
            return Column(children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                      controller: _search,
                      onChanged: _query,
                      decoration: const InputDecoration(
                          labelText: 'Search a place or address',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder()))),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.error))),
              if (_suggestions.isNotEmpty)
                ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 210),
                    child: ListView(shrinkWrap: true, children: [
                      for (final suggestion in _suggestions)
                        ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(suggestion.title),
                            subtitle: Text(suggestion.address),
                            onTap: () => _choose(suggestion)),
                    ])),
              Expanded(
                  child: widget.mapBuilder?.call(_center, _pin) ??
                      GoogleMap(
                          initialCameraPosition:
                              CameraPosition(target: _center, zoom: 14),
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          onMapCreated: (controller) => _map = controller,
                          onTap: _pin,
                          markers: {
                            if (_selection != null)
                              Marker(
                                  markerId: const MarkerId('meeting'),
                                  position: LatLng(_selection!.latitude,
                                      _selection!.longitude),
                                  draggable: true,
                                  onDragEnd: _pin)
                          })),
              SafeArea(
                  top: false,
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_selection?.label ??
                                'Search for a place, or tap the map to choose a meeting point.'),
                            if (_selection != null)
                              Text(
                                  '${_selection!.latitude.toStringAsFixed(5)}, ${_selection!.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                                onPressed: _selection == null || _loading
                                    ? null
                                    : () => Navigator.pop(context, _selection),
                                icon: const Icon(Icons.check),
                                label: const Text('Use this location')),
                          ]))),
            ]);
          }));
}
