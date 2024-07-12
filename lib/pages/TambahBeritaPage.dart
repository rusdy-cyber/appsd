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

  bool _isLoading = false;

  Future<void> _addBerita() async {
    final title = titleController.text;
    final paragraf = paragrafController.text;

    final prefs = await SharedPreferences.getInstance();
    final String? token =
        prefs.getString('token'); // Ambil token dari SharedPreferences

    if (token == null) {
      // Jika token tidak ada, navigasi ke halaman login
      Navigator.pushReplacementNamed(
          context, '/login'); // Ganti '/login' sesuai dengan route login Anda
      return;
    }

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
        Navigator.pop(context, true); // Kembali jika berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berita berhasil ditambahkan')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal menambahkan berita - Status Code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, silakan coba lagi')),
      );
      print('Error adding news: $e');
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
      appBar: AppBar(title: const Text('Tambah Berita')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: paragrafController,
              decoration: const InputDecoration(labelText: 'Paragraf'),
              maxLines: 5,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pilih Gambar (Opsional)'),
            ),
            const SizedBox(height: 20.0),
            if (imageFile != null)
              Text('Image: ${imageFile!.path.split('/').last}'),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    paragrafController.text.isNotEmpty) {
                  _addBerita(); // Panggil tanpa memeriksa gambar
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Pastikan semua field terisi')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
