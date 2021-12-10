import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

const classificationThreshold = 0.75;
const vocabFilename = 'assets/vocab';
const maxSentenceLength = 20;

void main() => runApp(const TFServingDemo());

class TFServingDemo extends StatefulWidget {
  const TFServingDemo({Key? key}) : super(key: key);

  @override
  _TFServingDemoState createState() => _TFServingDemoState();
}

class _TFServingDemoState extends State<TFServingDemo> {
  late Future<String> futurePrediction;
  Map<String, int> vocabMap = {};
  TextEditingController inputSentenceController = TextEditingController();
  late List<int> tokenIndices;

  @override
  void initState() {
    super.initState();
    futurePrediction = fetchPrediction();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TF Serving Flutter Demo Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TF Serving Flutter Demo Example'),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextField(
                    controller: inputSentenceController,
                    decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Enter a sentence here'),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        setState(() {
                          futurePrediction = fetchPrediction();
                        });
                      },
                      child: const Text("Classify")),
                  FutureBuilder<String>(
                    future: futurePrediction,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data!);
                      } else if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      }

                      // By default, show a loading spinner.
                      return const CircularProgressIndicator();
                    },
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  Future<String> fetchPrediction() async {
    if (vocabMap.isEmpty) {
      final vocabFileString = await rootBundle.loadString(vocabFilename);
      final lines = vocabFileString.split('\n');
      for (final l in lines) {
        var wordAndIndex = l.split(' ');
        (vocabMap)[wordAndIndex[0]] = int.parse(wordAndIndex[1]);
      }
    }

    final inputWords = inputSentenceController.text.split(' ');
    // Initialize with padding token
    tokenIndices = List.filled(maxSentenceLength, 0);
    tokenIndices[0] = 1; // Start token
    var i = 1;
    for (final w in inputWords) {
      if ((vocabMap).containsKey(w)) {
        tokenIndices[i] = (vocabMap)[w]!;
      } else {
        tokenIndices[i] = 2; // Unknown token
      }

      if (i++ >= maxSentenceLength - 2) {
        break; // Truncate the string if longer than 20
      }
    }

    final response = await http.post(
      // Using localhost
      Uri.parse('http://10.0.2.2:8501/v1/models/spam-detection:predict'),
      body: jsonEncode(<String, List<List<int>>>{
        'instances': [tokenIndices],
      }),
    );

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, dynamic> result = jsonDecode(response.body);
      if (result['predictions']![0][0] >= 1 - classificationThreshold) {
        return 'This sentence is not spam.';
      }
      return 'This sentence is spam.';
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Error response');
    }
  }
}
