import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main(List<String> args) => runApp(const WeatherApp());

class WeatherApp extends StatefulWidget {
  const WeatherApp({Key? key}) : super(key: key);

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int? temperature;
  String location = 'Jakarta';
  String weather = 'clear';
  int woeid = 1047378;
  String abbreviation = 'c';
  String errorMessage = '';

  // untuk list horizontal temperaturenya
  var minTempForecast = List.filled(7, 0);
  var maxTempForecast = List.filled(7, 0);
  var abbrForecast = List.filled(7, 'c');

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  @override
  initState() {
    super.initState();
    onTextFieldSubmitted(location);
  }

  Future<void> fetchSearch(String input) async {
    try {
      var searchResult = await http.get(Uri.parse(searchApiUrl + input));
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result['title'];
        woeid = result['woeid'];
      });
      errorMessage = "";
    } catch (e) {
      errorMessage =
          "We don't have data for city: $input, try another location";
    }
  }

  Future<void> fetchLocation() async {
    try {
      var locationResult =
          await http.get(Uri.parse(locationApiUrl + woeid.toString()));
      var result = json.decode(locationResult.body)['consolidated_weather'][0];
      setState(() {
        temperature = result['the_temp'].round();
        weather =
            result['weather_state_name'].replaceAll(' ', '').toLowerCase();
        abbreviation = result['weather_state_abbr'];
      });
    } catch (error) {}
  }

  Future<void> fetchLocationDay() async {
    // get now time
    var today = DateTime.now();
    var locationDayResult = await http.get(Uri.parse("$locationApiUrl$woeid/" +
        DateFormat('yyyy/MM/dd').format(today.add(Duration(days: 1)))));
    // convert the Api response to list then get first seven element of the list
    var result = json.decode(locationDayResult.body).sublist(0, 7);
    // for each object of the list, get min_temp, max_temp , and weather_state_abbr and put in corresponding list with corresponding index
    for (var i = 0; i < 7; i++) {
      setState(() {
        minTempForecast[i] = result[i]["min_temp"].round();
        maxTempForecast[i] = result[i]["max_temp"].round();
        abbrForecast[i] = result[i]["weather_state_abbr"];
      });
    }
  }

  onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
    await fetchLocationDay();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: temperature == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/$weather.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Image.network(
                            "https://www.metaweather.com/static/img/weather/png/$abbreviation.png",
                            width: 100,
                          ),
                        ),
                        Center(
                          child: Text(
                            temperature.toString() + '°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < 7; i++)
                              forecastElement(i + 1, abbrForecast[i],
                                  maxTempForecast[i], minTempForecast[i])
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 300,
                          child: TextField(
                            onSubmitted: (String input) {
                              onTextFieldSubmitted(input);
                            },
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search Another Location...',
                              hintStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: Platform.isAndroid ? 15 : 20),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

Widget forecastElement(
  int daysFromNow,
  String abbreviation,
  int maxTemp,
  int minTemp,
) {
  var now = DateTime.now();
  var someDaysFromNow = now.add(Duration(days: daysFromNow));
  bool isLast = someDaysFromNow.day - now.day == 7;
  return Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: isLast ? 16 : 0,
    ),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              DateFormat.E().format(someDaysFromNow),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              DateFormat.MMMd().format(someDaysFromNow),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16,
              ),
              child: Image.network(
                "https://www.metaweather.com/static/img/weather/png/$abbreviation.png",
                width: 50,
              ),
            ),
            Text(
              'High ' + maxTemp.toString() + '°C',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              'Low ' + minTemp.toString() + '°C',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    ),
  );
}
