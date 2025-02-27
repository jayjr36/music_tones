import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:music_tones/apilist.dart';
import 'package:music_tones/upload_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'ringtone_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RingtoneApp extends StatefulWidget {
  const RingtoneApp({super.key});

  @override
  _RingtoneAppState createState() => _RingtoneAppState();
}

class _RingtoneAppState extends State<RingtoneApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<dynamic> _songs = [];
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    fetchSongs();
  }

  // Request necessary permissions
  Future<void> requestPermissions() async {
    await Permission.storage.request();
    await Permission.requestInstallPackages.request();
  }

  // Fetch song list from Laravel API
  Future<void> fetchSongs() async {
    try {
      final response = await http.get(Uri.parse(Apilist.allSongs));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _songs = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load songs");
      }
    } catch (e) {
      print("Error fetching songs: $e");
      setState(() => _isLoading = false);
    }
  }

  // Play selected song
  Future<void> playSong(String url) async {
    try {
      print(url);
      await _audioPlayer.setUrl(url);
      _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Error playing song: $e");
    }
  }

  Future<void> pauseSong(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      print(e);
    }
  }

  // Download song
  Future<String?> downloadSong(String url, String fileName) async {
    try {
      Directory? dir = await getExternalStorageDirectory();
      String filePath = "${dir!.path}/$fileName";

      Dio dio = Dio();
      await dio.download(url, filePath);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Downloaded: $fileName")));
      return filePath;
    } catch (e) {
      print("Error downloading song: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Download failed")));
      return null;
    }
  }

  // Set downloaded song as ringtone
  Future<void> setRingtone(String url, String fileName) async {
    String? filePath = await downloadSong(url, fileName);
    if (filePath != null) {
      bool success = await RingtoneHelper.setRingtone(filePath);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? "Ringtone set successfully!"
              : "Failed to set ringtone")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Music Tones",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1a202c),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UploadSongScreen()));
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchSongs,
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFF1a202c),
                        ),
                        child: Icon(
                          Icons.music_note,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        song['title'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "Duration: ${song['duration']}",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: _currentlyPlayingUrl == song["stream_url"]
                                ? Icon(Icons.pause_circle)
                                : Icon(
                                    Icons.play_arrow,
                                    size: 30,
                                    color: Color(0xFF1a202c),
                                  ),
                            onPressed: () {
                              if (_currentlyPlayingUrl == song["stream_url"]) {
                                // If it's the same song, pause it
                                pauseSong(song["stream_url"]);
                                setState(() {
                                  _currentlyPlayingUrl =
                                      null; // No song is playing
                                });
                              } else {
                                // Play new song
                                playSong(song['stream_url']);
                                setState(() {
                                  _currentlyPlayingUrl = song[
                                      "stream_url"]; // Store playing song URL
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.download,
                              size: 30,
                              color: Color(0xFF1a202c),
                            ),
                            onPressed: () => downloadSong(
                                song['download_url'], "${song['title']}.mp3"),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.notifications,
                              size: 30,
                              color: Color(0xFF1a202c),
                            ),
                            onPressed: () => setRingtone(
                                song['url'], "${song['title']}.mp3"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
