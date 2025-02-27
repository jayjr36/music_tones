// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:ringtone_set/ringtone_set.dart';

// class MusicListScreen extends StatefulWidget {
//   @override
//   _MusicListScreenState createState() => _MusicListScreenState();
// }

// class _MusicListScreenState extends State<MusicListScreen> {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   List<File> musicFiles = [];

//   @override
//   void initState() {
//     super.initState();
//     requestPermissions();
//   }

//   Future<void> requestPermissions() async {
//     await Permission.storage.request();
//     await Permission.requestInstallPackages.request();
//     fetchMusicFiles();
//   }

//   void fetchMusicFiles() async {
//     Directory dir = Directory('/storage/emulated/0/Music'); 
//     List<FileSystemEntity> files = dir.listSync();

//     setState(() {
//       musicFiles = files.whereType<File>().where((file) {
//         return file.path.endsWith('.mp3') || file.path.endsWith('.wav');
//       }).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Music List')),
//       body: ListView.builder(
//         itemCount: musicFiles.length,
//         itemBuilder: (context, index) {
//           return ListTile(
//             title: Text(musicFiles[index].path.split('/').last),
//             trailing: Wrap(
//               children: [
//                 IconButton(
//                   icon: Icon(Icons.settings),
//                   onPressed: () => playMusic(musicFiles[index].path),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.settings),
//                   onPressed: () => setAsRingtone(musicFiles[index].path),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void playMusic(String path) async {
//     await _audioPlayer.play(DeviceFileSource(path));
//   }

//   void setAsRingtone(String path) async {
//     try {
//       await RingtoneSet.setRingtoneFromFile(
//         File(path),
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Ringtone set successfully")),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to set ringtone: $e")),
//       );
//     }
//   }
// }
