import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';
import 'TambahBeritaPage.dart'; // Ensure this import is correct

class BeritaListPage extends StatefulWidget {
  @override
  _BeritaListPageState createState() => _BeritaListPageState();
}

class _BeritaListPageState extends State<BeritaListPage> {
  List _beritaList = [];
  final ImagePicker _picker = ImagePicker();

  // Fetch berita dari API
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
      print('Error fetching berita: ${response.statusCode}');
    }
  }

  // Edit berita
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
      final responseString = await response.stream.bytesToString();
      print('Error updating berita: ${response.statusCode} - $responseString');
    }
  }

  // Hapus berita
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
      print('Error deleting berita: ${response.statusCode}');
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
            leading: berita['gambar'] != null
                ? Image.network(berita['gambar'])
                : null, // Show image if available
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
          // Navigasi ke halaman TambahBeritaPage
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TambahBeritaPage()),
          );

          // Jika berhasil menambah berita, ambil kembali berita
          if (result == true) {
            _fetchBerita();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  // Dialog untuk edit berita
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