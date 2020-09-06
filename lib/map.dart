import 'dart:convert';
import 'package:bird_alert/observations.dart';
import 'package:bird_alert/taxonomy.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'observations.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:flutter/services.dart';

class Map extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

enum Selection { Recent, Notable, Species }

class _MapState extends State<Map> {
  Completer<GoogleMapController> controller1;

  //State variables
  Selection currentSelection = Selection.Notable;
  String selectedSpecies = "";
  String selectedSpeciesCode = "";
  int daysBack = 1; //Days back for search
  int distance = 50; //distance of search
  static LatLng _initialPosition;
  final Set<Marker> _markers = {};
  String url = "";

  void _loadData() async {
    //Load taconomy data for the autocomplete field
    await TaxonomyViewModel.loadTaxonomy();
  }

  Future<Widget> showLoadingAlert() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              Text('Loading...'),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    _loadData();
    super.initState();
    _getUserLocation();
    _setMarkers(currentSelection);
  }

  void _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemark = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      print('${placemark[0].name}');
    });
  }

  _onMapCreated(GoogleMapController controller) {
    setState(() {
      controller1.complete(controller);
    });
  }

  MapType _currentMapType = MapType.normal;

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  openBrowserTab(String subId) async {
    await FlutterWebBrowser.openWebPage(
      url: "https://ebird.org/checklist?subID=$subId",
      androidToolbarColor: Colors.black12,
    );
  }

  _setMarkers(Selection selection) async {
    List<Observation> obs = [];
    Set<Marker> markers = {};
    LatLng currentPos;

    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    currentPos = LatLng(position.latitude, position.longitude);

    if (selection == Selection.Notable) {
      obs = await fetchNotableObservations(http.Client(), currentPos.latitude,
          currentPos.longitude, daysBack, distance);
    } else if (selection == Selection.Recent) {
      obs = await fetchRecentObservations(http.Client(), currentPos.latitude,
          currentPos.longitude, daysBack, distance);
    } else {
      obs = await fetchSpeciesObservations(http.Client(), currentPos.latitude,
          currentPos.longitude, daysBack, distance, selectedSpeciesCode);
    }

    for (var item in obs) {
      markers.add(Marker(
          markerId: MarkerId(item.subId),
          position: LatLng(item.lat, item.lng),
          infoWindow: InfoWindow(
              title: item.comName,
              onTap: () {
                return showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(item.comName),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('Location Details: ${item.locName}'),
                          Text(''),
                          Text('Number seen: ${item.howMany}'),
                          Text(''),
                          Text('Observation date: ${item.obsDt}'),
                          RaisedButton(
                              onPressed: () => openBrowserTab(
                                  item.subId), //Launch the checklist
                              child: Text('Checklist')),
                        ],
                      ),
                    );
                  },
                );
              }),
          onTap: () {},
          icon: BitmapDescriptor.defaultMarker));
    }
    _markers.clear();
    //Set state based on the returned list
    setState(() {
      _markers.addAll(markers);
    });
  }

  Widget mapButton(Function function, Icon icon, Color color) {
    return RawMaterialButton(
      onPressed: function,
      child: icon,
      shape: new CircleBorder(),
      elevation: 1.0,
      fillColor: color,
      padding: const EdgeInsets.all(7.0),
    );
  }

  AutoCompleteTextField searchTextField;
  GlobalKey<AutoCompleteTextFieldState<Taxonomy>> key = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black12,
        title: new Center(
          child: new Text('Bird Map'),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            FlatButton(
              onPressed: () {
                this.currentSelection = Selection.Recent;
                showLoadingAlert();
                _setMarkers(this.currentSelection)
                    .whenComplete(() => Navigator.pop(context));
              },
              child: Text("Recent Observations"),
              splashColor: Colors.black38,
              color: (this.currentSelection == Selection.Recent)
                  ? Colors.black38
                  : Colors.white10,
            ),
            FlatButton(
              onPressed: () {
                this.currentSelection = Selection.Notable;
                showLoadingAlert();
                _setMarkers(this.currentSelection)
                    .whenComplete(() => Navigator.pop(context));
              },
              child: Text("Notable Observations"),
              splashColor: Colors.black38,
              color: (this.currentSelection == Selection.Notable)
                  ? Colors.black38
                  : Colors.white10,
            ),
            FlatButton(
              onPressed: () {
                String comName = '';
                String spCode = '';

                return showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Species Observation'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('Common Name:'),
                          //******************************
                          searchTextField = AutoCompleteTextField<Taxonomy>(
                              style: new TextStyle(
                                  color: Colors.black, fontSize: 16.0),
                              decoration: new InputDecoration(
                                  suffixIcon: Container(
                                    width: 55.0,
                                    height: 40.0,
                                  ),
                                  filled: true,
                                  hintStyle: TextStyle(color: Colors.black)),
                              itemSubmitted: (item) {
                                setState(() {
                                  searchTextField.textField.controller.text =
                                      item.comName;
                                  comName = item.comName;
                                  spCode = item.speciesCode;
                                });
                              },
                              clearOnSubmit: false,
                              key: key,
                              suggestions: TaxonomyViewModel.taxonomy,
                              itemBuilder: (context, item) {
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      item.comName,
                                    ),
                                  ],
                                );
                              },
                              itemSorter: (a, b) {
                                return a.sciName.compareTo(b.comName);
                              },
                              itemFilter: (item, query) {
                                return (item.comName
                                    .toLowerCase()
                                    .startsWith(query.toLowerCase()));
                              }),
                          //**********************************
                        ],
                      ),
                      actions: <Widget>[
                        FlatButton(
                            child: Text("Submit"),
                            onPressed: () {
                              this.setState(() {
                                this.currentSelection = Selection.Species;
                                this.selectedSpecies = comName;
                                this.selectedSpeciesCode = spCode;
                                showLoadingAlert();
                                _setMarkers(this.currentSelection)
                                    .whenComplete(() => Navigator.pop(context));
                              });
                            }),
                      ],
                    );
                  },
                );
              },
              child: Column(
                children: <Widget>[
                  Text('Species Observation'),
                  Text('Current selections: ${this.selectedSpecies}'),
                ],
              ),
              splashColor: Colors.black38,
              color: (this.currentSelection == Selection.Species)
                  ? Colors.black38
                  : Colors.white10,
            ),
            IconButton(
                icon: Icon(Icons.settings),
                alignment: Alignment.bottomRight,
                onPressed: () {
                  return showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Settings"),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text("Days back: "),
                                DropdownButton<int>(
                                  value: this.daysBack,
                                  items: <int>[1, 2, 3, 4, 5, 6, 7]
                                      .map((int value) {
                                    return new DropdownMenuItem<int>(
                                      value: value,
                                      child: new Text(value.toString()),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    this.setState(() {
                                      this.daysBack = value;
                                      _setMarkers(this.currentSelection);
                                    });
                                  },
                                ),
                                Text("Radius (KM): "),
                                DropdownButton<int>(
                                  value: this.distance,
                                  items: <int>[5, 10, 20, 30, 40, 50]
                                      .map((int value) {
                                    return new DropdownMenuItem<int>(
                                      value: value,
                                      child: new Text(value.toString()),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    this.setState(() {
                                      this.distance = value;
                                      _setMarkers(this.currentSelection);
                                    });
                                  },
                                )
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
          ],
        ),
      ),
      //Body containg map
      body: _initialPosition == null
          ? Container(
              child: Center(
                child: Text(
                  'loading map..',
                  style: TextStyle(
                      fontFamily: 'Avenir-Medium', color: Colors.grey[400]),
                ),
              ),
            )
          : Container(
              child: Stack(children: <Widget>[
                GoogleMap(
                  markers: _markers,
                  mapType: _currentMapType,
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 14.4746,
                  ),
                  zoomGesturesEnabled: true,
                  myLocationEnabled: true,
                  compassEnabled: true,
                  myLocationButtonEnabled: false,
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                      margin: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                      child: Column(
                        children: <Widget>[
                          mapButton(
                              _onMapTypeButtonPressed,
                              Icon(
                                const IconData(0xf473,
                                    fontFamily: CupertinoIcons.iconFont,
                                    fontPackage:
                                        CupertinoIcons.iconFontPackage),
                              ),
                              Colors.green),
                        ],
                      )),
                )
              ]),
            ),
    );
  }
}
