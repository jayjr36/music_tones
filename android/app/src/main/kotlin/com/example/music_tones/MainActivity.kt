package com.example.music_tones

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException

class MainActivity: FlutterActivity() {
    private val CHANNEL = "custom_ringtone"
    private val REQUEST_CODE_WRITE_SETTINGS = 200

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setRingtone") {
                val filePath = call.argument<String>("filePath")
                val context = applicationContext
                if (filePath != null) {
                    if (Settings.System.canWrite(context)) {
                        val success = setRingtone(context, filePath)
                        result.success(success)
                    } else {
                        requestWriteSettingsPermission()
                        result.error("PERMISSION_DENIED", "WRITE_SETTINGS permission denied", null)
                    }
                } else {
                    result.error("INVALID_PATH", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun requestWriteSettingsPermission() {
        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
        intent.data = Uri.parse("package:$packageName")
        startActivityForResult(intent, REQUEST_CODE_WRITE_SETTINGS)
    }

    fun setRingtone(context: Context, filePath: String): Boolean {
        val resolver: ContentResolver = context.contentResolver
        val file = File(filePath)
    
        if (!file.exists()) {
            Log.e("Ringtone", "File does not exist: $filePath")
            return false
        }
    
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, file.name)
            put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
            put(MediaStore.Audio.Media.IS_RINGTONE, true)
            put(MediaStore.Audio.Media.IS_ALARM, true)
            put(MediaStore.Audio.Media.IS_NOTIFICATION, true)
            put(MediaStore.Audio.Media.IS_MUSIC, false)
        }
    
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }
    
        val uri: Uri? = resolver.insert(collection, values)
    
        uri?.let {
            try {
                resolver.openOutputStream(it)?.use { outputStream ->
                    FileInputStream(file).use { inputStream ->
                        val buffer = ByteArray(1024)
                        var bytesRead: Int
                        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                            outputStream.write(buffer, 0, bytesRead)
                        }
                    }
                }
    
                // Use the URI to set the default ringtone
                RingtoneManager.setActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE, it)
                Toast.makeText(context, "Ringtone set successfully!", Toast.LENGTH_SHORT).show()
                return true
            } catch (e: IOException) {
                Log.e("Ringtone", "Error copying file: ${e.message}")
            }
        } ?: run {
            Log.e("Ringtone", "Failed to insert file into MediaStore")
        }
    
        return false
    }
}
