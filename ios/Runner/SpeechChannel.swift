import Flutter
import Speech
import AVFoundation
import UIKit

/// Buffers stay on device. No recording files and no network fallback.
final class SpeechChannel: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var engine: AVAudioEngine?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var deadline: Timer?
  private var generation = 0
  private var active = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SpeechChannel()
    registrar.addMethodCallDelegate(instance,
      channel: FlutterMethodChannel(name: "mumumong/speech", binaryMessenger: registrar.messenger()))
    FlutterEventChannel(name: "mumumong/speech/events", binaryMessenger: registrar.messenger())
      .setStreamHandler(instance)
    NotificationCenter.default.addObserver(instance, selector: #selector(instance.background),
      name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(instance, selector: #selector(instance.background),
      name: AVAudioSession.interruptionNotification, object: nil)
  }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events; return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stop(); sink = nil; return nil
  }
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "stop" { stop(); result(nil); return }
    guard call.method == "start" else { result(FlutterMethodNotImplemented); return }
    stop()
    let token = generation
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR")),
      recognizer.supportsOnDeviceRecognition else {
      result(FlutterError(code: "on_device_unavailable", message: nil, details: nil)); return
    }
    SFSpeechRecognizer.requestAuthorization { [weak self] status in
      DispatchQueue.main.async {
        guard let self = self, self.generation == token else {
          result(FlutterError(code: "cancelled", message: nil, details: nil)); return
        }
        guard status == .authorized else {
          result(FlutterError(code: "permission_denied", message: nil, details: nil)); return
        }
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
          DispatchQueue.main.async {
            guard self.generation == token else {
              result(FlutterError(code: "cancelled", message: nil, details: nil)); return
            }
            guard allowed else {
              result(FlutterError(code: "permission_denied", message: nil, details: nil)); return
            }
            do { try self.begin(recognizer, token: token); result(nil) }
            catch { self.stop(); result(FlutterError(code: "audio_unavailable", message: nil, details: nil)) }
          }
        }
      }
    }
  }
  private func begin(_ recognizer: SFSpeechRecognizer, token: Int) throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
    try session.setActive(true)
    let audio = AVAudioEngine()
    let input = audio.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else { throw NSError(domain: "speech", code: 1) }
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = true
    self.request = request
    engine = audio
    active = true
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      request.append(buffer)
      guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return }
      var squares: Float = 0
      for i in 0..<Int(buffer.frameLength) { squares += samples[i] * samples[i] }
      let rms = sqrt(squares / Float(buffer.frameLength))
      DispatchQueue.main.async {
        guard let self = self, self.generation == token, self.active else { return }
        self.sink?(["rms": Double(rms)])
      }
    }
    task = recognizer.recognitionTask(with: request) { [weak self] response, error in
      DispatchQueue.main.async {
        guard let self = self, self.generation == token, self.active else { return }
        if let response = response {
          self.sink?(["text": response.bestTranscription.formattedString])
          if response.isFinal { self.stop() }
        } else if error != nil {
          self.sink?(["code": "recognition_unavailable"])
          self.stop()
        }
      }
    }
    audio.prepare()
    try audio.start()
    deadline = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { [weak self] _ in self?.stop() }
  }
  @objc private func background() { stop() }
  private func stop() {
    generation += 1
    deadline?.invalidate(); deadline = nil
    let wasActive = active
    active = false
    engine?.stop()
    engine?.inputNode.removeTap(onBus: 0)
    engine = nil
    request?.endAudio(); task?.cancel()
    request = nil; task = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    if wasActive { sink?(["stopped": true]) }
  }
  deinit { NotificationCenter.default.removeObserver(self) }
}
