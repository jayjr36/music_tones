import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tones/apilist.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  _UploadSongScreenState createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  List<Map<String, dynamic>> _selectedFiles = [];
  bool _isUploading = false;
  Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  // Request storage permissions
  Future<void> requestPermissions() async {
    await Permission.storage.request();
  }

// Pick multiple audio files
  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      List<Map<String, dynamic>> tempFiles = [];
      for (var file in result.files) {
        if (file.path != null) {
          String duration = await getAudioDuration(file.path!);
          tempFiles.add({
            "name": file.name,
            "path": file.path!,
            "duration": duration,
          });
        }
      }
      setState(() {
        _selectedFiles = tempFiles;
      });
    }
  }

// Get duration of an audio file
  Future<String> getAudioDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      await player.setFilePath(filePath);
      Duration? duration = player.duration;
      await player.dispose();
      if (duration != null) {
        return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
      }
    } catch (e) {
      print("Error getting duration: $e");
    }
    return "Unknown";
  }

// Upload selected files
  Future<void> uploadFiles() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No files selected!")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<MultipartFile> files = [];
      List<String> durations = [];
      for (var file in _selectedFiles) {
        files.add(
            await MultipartFile.fromFile(file["path"], filename: file["name"]));
        durations.add(file["duration"]);
        print(file);
      }

      FormData formData = FormData();

      for (int i = 0; i < files.length; i++) {
        formData.files
            .add(MapEntry("songs[]", files[i])); // Explicitly mark as an array
      }

      formData.fields.add(MapEntry(
          "durations", jsonEncode(durations))); // Send durations as JSON string

      Response response = await dio.post(
        Apilist.uploadUrl,
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );

      print(formData);

      if (response.statusCode == 200) {
        print(response);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload successful!")),
        );
        setState(() => _selectedFiles.clear());
      } else {
        print(response);
        throw Exception("Upload failed");
      }
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed")),
      );
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Songs"), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Select Songs Button
            ElevatedButton.icon(
              onPressed: pickFiles,
              icon: Icon(Icons.folder_open),
              label: Text("Select Songs"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),

            SizedBox(height: 20),

            // Selected Songs List
            if (_selectedFiles.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final song = _selectedFiles[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: ListTile(
                        leading: Icon(Icons.music_note,
                            color: Colors.red.shade700, size: 30),
                        title: Text(song["name"],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Duration: ${song["duration"]}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => _selectedFiles.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
              ),

            SizedBox(height: 20),

            // Upload Button (Hidden when no file is selected)
            if (_selectedFiles.isNotEmpty)
              _isUploading
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: uploadFiles,
                      icon: Icon(Icons.cloud_upload),
                      label: Text("Upload Songs"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
