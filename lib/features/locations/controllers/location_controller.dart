import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/location_model.dart';
import '../../../data/repositories/features/location_repository.dart';
import '../../../utils/popups/snackbars.dart';

/// 📍 LocationController — manages live location + history + map state
///
/// Features:
///  ✅ Real-time live location stream
///  ✅ Location history stream (today)
///  ✅ Map markers + polylines (movement trail)
///  ✅ Camera animation on location update
///  ✅ Stats computation (distance traveled, etc.)
///  ✅ Request sync from child
///  ✅ Open in Google Maps app
///  ✅ 🔥 Multi-source location support (GPS / Cell Tower / Cached)
///  ✅ 🔥 Location type-aware UI (show warnings for OFF / Approximate)
class LocationController extends GetxController {
  LocationController({required this.childUid});

  final String childUid;

  final LocationRepository _repository = LocationRepository();

  // ============ Reactive state ============
  final Rx<LocationModel?> liveLocation = Rx<LocationModel?>(null);
  final RxList<LocationModel> history = <LocationModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;

  // Map state
  final Rx<CameraPosition?> cameraPosition = Rx<CameraPosition?>(null);
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxBool followLiveLocation = true.obs;

  // Stats
  final Rx<LocationStats?> stats = Rx<LocationStats?>(null);

  // Google Maps controller
  GoogleMapController? _mapController;
  StreamSubscription<LocationModel?>? _liveSub;
  StreamSubscription<List<LocationModel>>? _historySub;

  @override
  void onInit() {
    super.onInit();
    _initStreams();
  }

  @override
  void onClose() {
    _liveSub?.cancel();
    _historySub?.cancel();
    _mapController?.dispose();
    super.onClose();
  }

  /// Initialize real-time streams
  void _initStreams() {
    // Live location stream
    _liveSub = _repository.streamLiveLocation(childUid).listen(
      (location) {
        liveLocation.value = location as LocationModel?;
        error.value = '';

        if (location != null && location.canShowOnMap) {
          _updateMapMarkers(location);
          if (followLiveLocation.value) {
            _animateCamera(location);
          }
        }
        isLoading.value = false;
        isRefreshing.value = false;
      },
      onError: (err) {
        error.value = 'Error loading location: $err';
        isLoading.value = false;
        isRefreshing.value = false;
      },
    );

    // History stream (today)
    _isLoadingHistory();
    _historySub = _repository.streamTodayHistory(childUid).listen(
      (locations) {
        history.value = locations;
        stats.value = _repository.computeStats(locations);
        _updatePolylines(locations);
        isLoadingHistory.value = false;
      },
      onError: (err) {
        print('History stream error: $err');
        isLoadingHistory.value = false;
      },
    );
  }

  void _isLoadingHistory() => isLoadingHistory.value = true;

  // ============ MAP METHODS ============

  /// Called when GoogleMap is created
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // If we already have location, move camera
    if (liveLocation.value != null && liveLocation.value!.canShowOnMap) {
      _animateCamera(liveLocation.value!);
    }
  }

  /// Update markers on the map
  void _updateMapMarkers(LocationModel location) {
    if (!location.canShowOnMap) return;

    // 🔥 Marker color based on location type
    final markerHue = _getMarkerHue(location);

    final marker = Marker(
      markerId: const MarkerId('child_live'),
      position: LatLng(location.lat, location.lng),
      infoWindow: InfoWindow(
        title: 'Child',
        snippet: '${location.timeAgo} • ${location.accuracyLabel}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
    );

    markers.value = {marker};
  }

  /// 🔥 Get marker color based on location type
  double _getMarkerHue(LocationModel location) {
    if (location.isMocked) {
      return BitmapDescriptor.hueOrange;
    }
    switch (location.locationType) {
      case LocationType.gps:
        return BitmapDescriptor.hueAzure;
      case LocationType.cached:
        return BitmapDescriptor.hueViolet;
      case LocationType.unknown:
        return BitmapDescriptor.hueAzure;
    }
  }

  /// Draw polyline connecting history points (movement trail)
  void _updatePolylines(List<LocationModel> locations) {
    if (locations.length < 2) {
      polylines.clear();
      return;
    }

    // Reverse to get chronological order (oldest first)
    final chronological = List<LocationModel>.from(locations).reversed.toList();

    // 🔥 Only include valid mappable points for polyline
    final points = chronological
        .where((l) => l.canShowOnMap)
        .map((l) => LatLng(l.lat, l.lng))
        .toList();

    if (points.length < 2) {
      polylines.clear();
      return;
    }

    final polyline = Polyline(
      polylineId: const PolylineId('movement_trail'),
      points: points,
      color: const Color(0xFFFBAB57),
      width: 4,
      patterns: [],
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    polylines.value = {polyline};
  }

  /// Animate camera to location
  void _animateCamera(LocationModel location) {
    if (_mapController == null) return;

    // 🔥 Different zoom levels based on accuracy
    final zoom = _getZoomLevel(location);

    final position = CameraPosition(
      target: LatLng(location.lat, location.lng),
      zoom: zoom,
    );
    cameraPosition.value = position;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(position),
    );
  }

  /// 🔥 Get appropriate zoom level based on location accuracy
  double _getZoomLevel(LocationModel location) {
    switch (location.locationType) {
      case LocationType.gps:
        return 16.0;
      case LocationType.cached:
        return 15.0;
      default:
        return 14.0;
    }
  }

  /// Center map on live location (manual trigger)
  void centerOnLiveLocation() {
    final loc = liveLocation.value;
    if (loc != null && loc.canShowOnMap) {
      followLiveLocation.value = true;
      _animateCamera(loc);
    } else {
      USnackBarHelpers.warningSnackBar(
        title: 'No Location',
        message: 'Live location not available — check child device settings',
      );
    }
  }

  /// Toggle follow mode
  void toggleFollowLiveLocation() {
    followLiveLocation.value = !followLiveLocation.value;
    if (followLiveLocation.value) {
      centerOnLiveLocation();
      USnackBarHelpers.infoSnackBar(
        title: 'Follow Mode',
        message: 'Following live location',
      );
    } else {
      USnackBarHelpers.infoSnackBar(
        title: 'Manual Mode',
        message: 'Free map navigation',
      );
    }
  }

  // ============ ACTIONS ============

  /// Manual refresh
  Future<void> refreshData() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    try {
      // 🔥 First request sync from child
      await _repository.requestSync(childUid);

      // 🔥 Then fetch latest from Firestore
      final location = await _repository.getLiveLocation(childUid);
      if (location != null) {
        liveLocation.value = location;
        if (location.canShowOnMap) {
          _updateMapMarkers(location);
          if (followLiveLocation.value) _animateCamera(location);
        }
      }
      USnackBarHelpers.successSnackBar(
        title: 'Sync Requested',
        message: 'Asked child device to send fresh location',
      );
    } catch (e) {
      USnackBarHelpers.errorSnackBar(
        title: 'Refresh Failed',
        message: e.toString(),
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Open location in Google Maps app
  Future<void> openInGoogleMaps() async {
    final loc = liveLocation.value;
    if (loc == null || !loc.canShowOnMap) {
      USnackBarHelpers.warningSnackBar(
        title: 'No Location',
        message: 'Live location not available',
      );
      return;
    }
    // Use url_launcher to open Google Maps
    final url = Uri.parse(loc.googleMapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      USnackBarHelpers.errorSnackBar(
        title: 'Error',
        message: 'Could not open Google Maps',
      );
    }
  }

  /// Get directions to child location
  Future<void> getDirections() async {
    final loc = liveLocation.value;
    if (loc == null || !loc.canShowOnMap) {
      USnackBarHelpers.warningSnackBar(
        title: 'No Location',
        message: 'Live location not available',
      );
      return;
    }

    final url = Uri.parse(loc.googleMapsDirectionsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      USnackBarHelpers.errorSnackBar(
        title: 'Error',
        message: 'Could not open directions',
      );
    }
  }

  // ============ COMPUTED GETTERS ============

  LocationModel? get location => liveLocation.value;

  bool get hasLocation => liveLocation.value?.isValid ?? false;

  bool get canShowOnMap => liveLocation.value?.canShowOnMap ?? false;

  bool get isMocked => liveLocation.value?.isMocked ?? false;

  bool get isLocationOff {
    final loc = liveLocation.value;
    if (loc == null) return false;
    return !loc.isLocationServiceOn;
  }

  bool get isApproximate {
    final loc = liveLocation.value;
    if (loc == null) return false;
    return loc.isApproximateLocation;
  }

  /// 🔥 Whether location is from cache
  bool get isFromCache => liveLocation.value?.isFromCache ?? false;

  /// 🔥 Location type
  LocationType? get locationType => liveLocation.value?.locationType;

  String get address => liveLocation.value?.address ?? 'Address unavailable';

  String get coordinates =>
      liveLocation.value?.coordinatesFormatted ?? 'N/A';

  String get timeAgo => liveLocation.value?.timeAgo ?? 'Never';

  String get accuracyLabel => liveLocation.value?.accuracyLabel ?? 'Unknown';

  String get speedLabel => liveLocation.value?.speedLabel ?? 'Unknown';

  /// 🔥 Provider label (human-readable)
  String get providerLabel => liveLocation.value?.providerLabel ?? 'Unknown';

  /// 🔥 Provider icon (emoji)
  String get providerIcon => liveLocation.value?.providerIcon ?? '❓';

  /// 🔥 Status message for UI
  String get statusMessage => liveLocation.value?.statusMessage ?? '';

  int get historyCount => history.length;

  String get distanceTraveled => stats.value?.distanceFormatted ?? '0 km';

  /// Calculate initial camera position (or default)
  CameraPosition get initialCameraPosition {
    final loc = liveLocation.value;
    if (loc != null && loc.canShowOnMap) {
      return CameraPosition(
        target: LatLng(loc.lat, loc.lng),
        zoom: _getZoomLevel(loc),
      );
    }
    // Default: New Delhi
    return const CameraPosition(
      target: LatLng(28.6139, 77.2090),
      zoom: 10.0,
    );
  }
}
