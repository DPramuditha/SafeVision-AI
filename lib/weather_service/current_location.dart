import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class CurrentLocation {
  Future<String> getCurrentLocation() async{
    try{
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return '❌Location services are disabled. Please enable them.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if(permission == LocationPermission.denied){
        permission = await Geolocator.requestPermission();
        if(permission == LocationPermission.denied){
          return '❌Location permissions are denied. Please enable them in settings.';
        }
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // return '✅Current Location: ${position.latitude}, ${position.longitude}';
      print('✅Current Location: ${position.latitude}, ${position.longitude}'); 

      List<Placemark> placemark = await placemarkFromCoordinates(position.latitude, position.longitude);

      if(placemark.isNotEmpty){
        String? city = placemark[0].locality;
        String? country = placemark[0].country;
        // return '✅Current Location: $city, $country';
        if(city != null){
          print('✅Current Location: $city, $country');
          return '✅Current Location: $city, $country';
        } else {
          print('❌City not found');
          return '❌City not found';
        }
      }
      else{
        return '❌No placemark found for the current location.';
      }

    }
    catch (e) {
      print('❌Error getting current location: $e');
      return '❌Error getting current location: $e';
    }

  }

}