import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(home: SmartAssistant()));
}

class SmartAssistant extends StatefulWidget {
  @override
  _SmartAssistantState createState() => _SmartAssistantState();
}

class _SmartAssistantState extends State<SmartAssistant> {
  SpeechToText speech = SpeechToText();
  FlutterTts flutterTts = FlutterTts();
  String task = '';
  List<Map> tasks = [];
  String selectedType = 'work';
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> getSuggestion(String task, String type) async {
    var response = await http.post(
      Uri.parse('https://your-backend-url.onrender.com/suggest'),
      body: {'task': task, 'type': type},
    );
    var result = jsonDecode(response.body);
    String suggestedTime = result['time'];
    setState(() {
      tasks.add({'task': task, 'time': suggestedTime, 'type': type});
    });
    speak("Scheduled $task at $suggestedTime for $type");
  }

  void startListening() async {
    bool available = await speech.initialize();
    if (available) {
      speech.listen(onResult: (val) {
        setState(() {
          task = val.recognizedWords;
        });
      });
    }
  }

  void _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  void _addManualTask() {
    if (task.isNotEmpty) {
      setState(() {
        tasks.add({
          'task': task,
          'time': selectedTime.format(context),
          'type': selectedType
        });
        speak("Added $task at ${selectedTime.format(context)}");
        task = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC),
      appBar: AppBar(
        title: Text("Smart Routine Assistant"),
        actions: [
          IconButton(
            icon: Icon(Icons.list_alt),
            onPressed: _addManualTask,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedType,
              items: ['work', 'exercise', 'study', 'rest']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedType = value!),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: "Enter Task",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => task = val,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Pick Time: ${selectedTime.format(context)}"),
                ElevatedButton(
                  onPressed: _pickTime,
                  child: Text("Select Time"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: tasks.map((t) => ListTile(
                      title: Text("${t['task']} - ${t['time']}"),
                      subtitle: Text(t['type']),
                    )).toList(),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: GestureDetector(
            onTap: startListening,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade100,
                    offset: Offset(-6.0, -6.0),
                    blurRadius: 10.0,
                  ),
                  BoxShadow(
                    color: Colors.deepPurple.shade200,
                    offset: Offset(6.0, 6.0),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: Icon(Icons.mic, size: 40, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}