import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_api_headers/google_api_headers.dart';

// this is the main function
void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

// this is the main app
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// use your api key here
const kGoogleApiKey = 'API_KEY_HERE';

// this is the key of the homeScaffold
final homeScaffoldKey = GlobalKey<ScaffoldState>();

// this is the state of the app
class _MyAppState extends State<MyApp> {
  static const CameraPosition initialCameraPosition =
      CameraPosition(target: LatLng(37.42796, -122.08574), zoom: 14.0);

  // this will hold the markers
  Set<Marker> markersList = {};

  // this will hold the google map controller
  late GoogleMapController googleMapController;

  // this will hold the mode given to the PlacesAutocomplete
  final Mode _mode = Mode.overlay;

  // this will build the app
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: homeScaffoldKey,
      appBar: AppBar(
        title: const Text("Google search places"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            markers: markersList,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              googleMapController = controller;
            },
          ),
          ElevatedButton(
              onPressed: _handlePressButton, child: const Text("Search Places"))
        ],
      ),
    );
  }

  // this will handle the search button
  Future<void> _handlePressButton() async {
    Prediction? p = await PlacesAutocomplete.show(
        context: context,
        apiKey: kGoogleApiKey,
        onError: onError,
        mode: _mode,
        language: 'en',
        strictbounds: false,
        types: [""],
        decoration: InputDecoration(
            hintText: 'Search',
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.white))),
        components: [
          Component(Component.country, "kr"),
          Component(Component.country, "us")
        ]);

    // this will display the prediction
    displayPrediction(p!, homeScaffoldKey.currentState);
  }

  // this will display an error if the search fails
  void onError(PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Message',
        message: response.errorMessage!,
        contentType: ContentType.failure,
      ),
    ));
  }

  // this will display the prediction
  Future<void> displayPrediction(
      Prediction p, ScaffoldState? currentState) async {
    GoogleMapsPlaces places = GoogleMapsPlaces(
        apiKey: kGoogleApiKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders());

    // this will get the details of the place
    PlacesDetailsResponse detail = await places.getDetailsByPlaceId(p.placeId!);

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;
    final openingHoursResult =
        detail.result.openingHours?.weekdayText.join("\n");

    // this will display the details of the place including the location and opening hours
    // ignore: use_build_context_synchronously
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(detail.result.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Location: $lat, $lng"),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Opening Hours:"),
                      Text("$openingHoursResult"),
                    ],
                  ),
                ),
              ],
            ),
          );
        });

    // this will set the marker on the map
    setState(() {
      markersList.clear();
      markersList.add(Marker(
          markerId: const MarkerId("0"),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: detail.result.name)));
    });

    googleMapController
        .animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0));
  }
}
