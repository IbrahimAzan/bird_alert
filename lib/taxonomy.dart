import 'package:flutter/services.dart';
import 'dart:convert';

//Class to parse json taxonomy objects (from assets/taxonomy.json) for use in autocomplete field
class Taxonomy {
  String sciName;
  String comName;
  String speciesCode;

  Taxonomy({this.sciName, this.comName, this.speciesCode});

  factory Taxonomy.fromJson(Map<String, dynamic> parsedJson) {
    return Taxonomy(
        sciName: parsedJson['sciName'] as String,
        comName: parsedJson['comName'] as String,
        speciesCode: parsedJson['speciesCode'] as String);
  }
}

//Taxonomy view model
class TaxonomyViewModel {
  static List<Taxonomy> taxonomy;

  static Future<List<Taxonomy>> loadTaxonomy() async {
    try {
      taxonomy = new List<Taxonomy>();
      String jsonString = await rootBundle.loadString('assets/taxonomy.json');
      var parsedJson = json.decode(jsonString);
      var categoryJson = parsedJson['taxonomy'] as List;
      for (int i = 0; i < categoryJson.length; i++) {
        taxonomy.add(new Taxonomy.fromJson(categoryJson[i]));
      }
    } catch (e) {
      print(e);
    }

    return taxonomy;
  }
}
