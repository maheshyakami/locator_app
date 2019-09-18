import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/directions.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:location/location.dart' as LM;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController mapController;
  final _places = GoogleMapsPlaces(apiKey: "YOUR_API_KEY");

  Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = const LatLng(27.6710, 85.4298);
  final Set<Marker> _markers = {};
  LatLng _lastMapPosition = _center;
  MapType _currentMapType = MapType.normal;

  var location = LM.Location(); // type was Location before var
  List<PlacesSearchResult> places = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Locator"),
        elevation: defaultTargetPlatform == TargetPlatform.android ? 5.0 : 0.0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: refresh,
          )
        ],
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: _currentMapType,
            markers: _markers,
            compassEnabled: true,
            onCameraMove: _onCameraMove,
          ),
          Positioned(
            top: 50,
            right: 10,
            child: FloatingActionButton(
              onPressed: _mapType,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              tooltip: "Switch Map Type",
              child: Icon(
                Icons.map,
                color: Colors.white,
                size: 36.0,
              ),
              backgroundColor: Colors.green,
            ),
          )
        ],
      ),
    );
  }

  void refresh() async {
    final center = await getUserLocation();

    final location = Location(center.latitude, center.longitude);
    final result =
        await _places.searchNearbyWithRadius(location, 1000, type: "gym");
    setState(() {
      if (result.status == "OK") {
        this.places = result.results;
        result.results.forEach((f) {
          _markers.add(Marker(
              markerId: MarkerId(f.id.toString()),
              position:
                  LatLng(f.geometry.location.lat, f.geometry.location.lng),
              infoWindow: InfoWindow(
                  title: f.name, snippet: f.types?.first, onTap: () {})));
          print(f.id);
          print(f.name); // marks only single instance
        });
      } else {
        print(result.errorMessage);
      }
    });
  }

  Future<LatLng> getUserLocation() async {
    LM.LocationData currentLocation;
    try {
      currentLocation = await location.getLocation();
      final lat = currentLocation.latitude;
      final lng = currentLocation.longitude;
      final center = LatLng(lat, lng);
      return center;
    } on Exception {
      currentLocation = null;
      return null;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _mapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }
}
