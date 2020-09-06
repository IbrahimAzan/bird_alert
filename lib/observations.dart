import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Observation {
  final String comName;
  final String locName;
  final int howMany;
  final String obsDt;
  final double lat;
  final double lng;
  final String subId;

  Observation(
      {@required this.comName,
      @required this.locName,
      @required this.howMany,
      @required this.obsDt,
      @required this.lat,
      @required this.lng,
      @required this.subId});

  factory Observation.fromJson(Map<dynamic, dynamic> json) {
    return Observation(
      comName: json['comName'] as String,
      locName: json['locName'] as String,
      howMany: json['howMany'] as int,
      obsDt: json['obsDt'] as String,
      lat: json['lat'] as double,
      lng: json['lng'] as double,
      subId: json['subId'] as String,
    );
  }
}

Map<String, String> get headers => {
      "X-eBirdApiToken": "YOUR-EBIRD-API-KEY",
    };

List<Observation> parseObservations(String response) {
  final parsed = json.decode(response).cast<Map<String, dynamic>>();

  return parsed.map<Observation>((json) => Observation.fromJson(json)).toList();
}

Future<List<Observation>> fetchNotableObservations(http.Client client,
    double lat, double lng, int daysBack, int distance) async {
  String url =
      "https://api.ebird.org/v2/data/obs/geo/recent/notable?lat=$lat&lng=$lng&back=$daysBack&dist=$distance";
  var response = await http.get(url, headers: headers);

  if (response.statusCode != 200) {
    throw Exception(
        "Request to $url failed with status ${response.statusCode}: ${response.body}");
  }

  return parseObservations(response.body);
}

Future<List<Observation>> fetchRecentObservations(http.Client client,
    double lat, double lng, int daysBack, int distance) async {
  String url =
      "https://api.ebird.org/v2/data/obs/geo/recent?lat=$lat&lng=$lng&back=$daysBack&dist=$distance";
  var response = await http.get(url, headers: headers);

  if (response.statusCode != 200) {
    throw Exception(
        "Request to $url failed with status ${response.statusCode}: ${response.body}");
  }

  return parseObservations(response.body);
}

Future<List<Observation>> fetchSpeciesObservations(
    http.Client client,
    double lat,
    double lng,
    int daysBack,
    int distance,
    String speciesCode) async {
  String url =
      "https://api.ebird.org/v2/data/nearest/geo/recent/$speciesCode?lat=$lat&lng=$lng&back=$daysBack&dist=$distance";
  var response = await http.get(url, headers: headers);

  if (response.statusCode != 200) {
    throw Exception(
        "Request to $url failed with status ${response.statusCode}: ${response.body}");
  }

  return parseObservations(response.body);
}
