import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';

class BeritaListPage extends StatefulWidget {
  @override
  _BeritaListPageState createState() => _BeritaListPageState();
}

class _BeritaListPageState extends State<BeritaListPage> {
  List _beritaList = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _fetchBerita() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.11.9.19:8080/api/berita?adminId=1'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _beritaList = data;
      });
    } else {
      // Handle error
    }
  }

  Future<void> _addBerita(String title, String paragraf, File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.11.9.19:8080/api/berita'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['paragraf'] = paragraf;
    request.files
        .add(await http.MultipartFile.fromPath('gambar', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      _fetchBerita();
    } else {
      // Handle error
    }
  }

  Future<void> _editBerita(
      int id, String title, String paragraf, File? imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('http://10.11.9.19:8080/api/berita/$id'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['paragraf'] = paragraf;
    if (imageFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath('gambar', imageFile.path));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      _fetchBerita();
    } else {
      // Handle error
    }
  }

  Future<void> _deleteBerita(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('http://10.11.9.19:8080/api/berita/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _fetchBerita();
    } else {
      // Handle error
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBerita();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Berita List')),
      body: ListView.builder(
        itemCount: _beritaList.length,
        itemBuilder: (context, index) {
          final berita = _beritaList[index];
          return ListTile(
            leading: Image.network(berita['gambar']),
            title: Text(berita['title']),
            subtitle: Text(berita['paragraf']),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(berita);
                } else if (value == 'delete') {
                  _deleteBerita(berita['id']);
                }
              },
              itemBuilder: (BuildContext context) {
                return {'edit', 'delete'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final titleController = TextEditingController();
          final paragrafController = TextEditingController();
          File? imageFile;

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Tambah Berita'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: paragrafController,
                    decoration: InputDecoration(labelText: 'Paragraf'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        imageFile = File(pickedFile.path);
                      }
                    },
                    child: Text('Pilih Gambar'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (imageFile != null) {
                      _addBerita(titleController.text, paragrafController.text,
                          imageFile!);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Tambah'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> berita) async {
    final titleController = TextEditingController(text: berita['title']);
    final paragrafController = TextEditingController(text: berita['paragraf']);
    File? imageFile;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Berita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: paragrafController,
              decoration: InputDecoration(labelText: 'Paragraf'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  imageFile = File(pickedFile.path);
                }
              },
              child: Text('Pilih Gambar'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _editBerita(berita['id'], titleController.text,
                  paragrafController.text, imageFile);
              Navigator.of(context).pop();
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }
}
