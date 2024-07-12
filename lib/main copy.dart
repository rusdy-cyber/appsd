import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class TambahBeritaPage extends StatefulWidget {
  @override
  _TambahBeritaPageState createState() => _TambahBeritaPageState();
}

class _TambahBeritaPageState extends State<TambahBeritaPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController paragrafController = TextEditingController();
  File? imageFile;
  String? errorMessage;

  Future<void> _addBerita(String title, String paragraf) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.11.9.19:8080/api/berita'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['paragraf'] = paragraf;
    if (imageFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath('gambar', imageFile!.path));
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        final responseBody = await response.stream.bytesToString();
        setState(() {
          errorMessage = 'Error: ${responseBody}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Berita')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: paragrafController,
              decoration: InputDecoration(labelText: 'Paragraf'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pilih Gambar'),
            ),
            SizedBox(height: 20.0),
            if (imageFile != null)
              Text('Image: ${imageFile!.path.split('/').last}'),
            SizedBox(height: 20.0),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    paragrafController.text.isNotEmpty &&
                    imageFile != null) {
                  _addBerita(titleController.text, paragrafController.text);
                } else {
                  setState(() {
                    errorMessage =
                        'Please fill in all fields and select an image.';
                  });
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
