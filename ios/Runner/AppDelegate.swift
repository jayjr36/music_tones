import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)

       let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let ringtoneChannel = FlutterMethodChannel(name: "custom_ringtone",
                                                  binaryMessenger: controller.binaryMessenger)
        ringtoneChannel.setMethodCallHandler { (call, result) in
            if call.method == "saveRingtone" {
                if let args = call.arguments as? [String: Any],
                   let filePath = args["filePath"] as? String {
                    self.saveRingtoneToFiles(filePath: filePath, result: result)
                } else {
                    result(FlutterError(code: "INVALID_PATH", message: "File path is missing", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func saveRingtoneToFiles(filePath: String, result: FlutterResult) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent("ringtone.m4r")

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(atPath: filePath, toPath: destinationURL.path)
            result(true)
        } catch {
            result(FlutterError(code: "SAVE_ERROR", message: "Could not save file", details: nil))
        }
    }
  }

