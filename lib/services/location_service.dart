import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String? _currentAddress;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;

  /// Check and request location permission
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = _formatAddress(place);
        return _currentAddress;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Get current address
  Future<String?> getCurrentAddress() async {
    final position = await getCurrentLocation();
    if (position != null) {
      return await getAddressFromCoordinates(position.latitude, position.longitude);
    }
    return null;
  }

  /// Format placemark to readable address
  String _formatAddress(Placemark place) {
    List<String> parts = [];
    
    if (place.subLocality?.isNotEmpty ?? false) {
      parts.add(place.subLocality!);
    }
    if (place.locality?.isNotEmpty ?? false) {
      parts.add(place.locality!);
    }
    if (place.subAdministrativeArea?.isNotEmpty ?? false) {
      parts.add(place.subAdministrativeArea!);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Lokasi tidak diketahui';
  }

  /// Calculate distance between two points in km
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toInt()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.toInt()} km';
    }
  }

  /// Open location in maps app
  Future<bool> openInMaps(double lat, double lng, {String? label}) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
    );
    
    final Uri appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?q=$lat,$lng'
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        return await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Open navigation to location
  Future<bool> openNavigation(double destLat, double destLng) async {
    final position = _currentPosition ?? await getCurrentLocation();
    
    if (position == null) {
      // Open destination only without navigation
      return openInMaps(destLat, destLng);
    }

    final Uri googleMapsNavUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=$destLat,$destLng&travelmode=driving'
    );

    try {
      if (await canLaunchUrl(googleMapsNavUrl)) {
        return await launchUrl(googleMapsNavUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Get coordinates from address
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations[0];
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
