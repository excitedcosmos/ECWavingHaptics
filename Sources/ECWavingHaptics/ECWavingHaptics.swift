/**
 ECWavingHaptics

 特征和特性：
 1. 结合音频处理和触觉反馈，提供实时的音频可感知化体验
 2. 支持自定义音频文件和频率范围
 3. 提供循环播放选项
 4. 实现了后台暂停和前台恢复功能
 5. 使用 Core Haptics 框架提供触觉反馈
 6. 利用 Accelerate 框架进行高效的 FFT 计算

 注意事项：
 1. 需要 iOS 13.0 或更高版本，因为使用了 Core Haptics 框架
 2. 触觉反馈依赖于设备硬件支持，部分设备可能不支持
 3. 音频处理可能会增加设备的电池消耗
 4. 大文件或高采样率的音频可能会影响性能

 使用方法：
 1. 创建 ECWavingHaptics 实例：
    let haptics = ECWavingHaptics(
        audioFileURL: URL(fileURLWithPath: "path/to/audio/file"),
        audioFormat: AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!,
        minFrequency: 20,
        maxFrequency: 20000,
        isLooping: true,
        playCallback: { print("开始播放") },
        stopCallback: { print("停止播放") },
        errorCallback: { error in print("错误：\(error)") }
    )
    
    参数说明：
    - audioFileURL: 音频文件的 URL
    - audioFormat: 音频格式，包括采样率和通道数
    - minFrequency: 最小频率，单位为 Hz
    - maxFrequency: 最大频率，单位为 Hz
    - isLooping: 是否循环播放
    - playCallback: 开始播放时的回调函数
    - stopCallback: 停止播放时的回调函数
    - errorCallback: 发生错误时的回调函数

 2. 开始音频处理和触觉反馈：
    haptics.startAudioProcessing()

 3. 停止音频处理和触觉反馈：
    haptics.stopAudioProcessing()

 4. 在适当的时机释放资源：
    deinit {
        haptics.stopAudioProcessing()
    }

 ECWavingHaptics Class

 Features and Characteristics:
 1. Combines audio processing and haptic feedback to provide real-time audio  sensorization experience
 2. Supports custom audio files and frequency ranges
 3. Offers looping playback option
 4. Implements background pause and foreground resume functionality
 5. Uses Core Haptics framework for haptic feedback
 6. Utilizes Accelerate framework for efficient FFT calculations

 Notes:
 1. Requires iOS 13.0 or higher due to the use of Core Haptics framework
 2. Haptic feedback depends on device hardware support, some devices may not support it
 3. Audio processing may increase device battery consumption
 4. Large files or high sample rate audio may affect performance

 Usage:
 1. Create an ECWavingHaptics instance:
    let haptics = ECWavingHaptics(
        audioFileURL: URL(fileURLWithPath: "path/to/audio/file"),
        audioFormat: AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!,
        minFrequency: 20,
        maxFrequency: 20000,
        isLooping: true,
        playCallback: { print("Playback started") },
        stopCallback: { print("Playback stopped") },
        errorCallback: { error in print("Error: \(error)") }
    )
    
    Parameter description:
    - audioFileURL: URL of the audio file
    - audioFormat: Audio format, including sample rate and number of channels
    - minFrequency: Minimum frequency in Hz
    - maxFrequency: Maximum frequency in Hz
    - isLooping: Whether to loop playback
    - playCallback: Callback function when playback starts
    - stopCallback: Callback function when playback stops
    - errorCallback: Callback function when an error occurs

 2. Start audio processing and haptic feedback:
    haptics.startAudioProcessing()

 3. Stop audio processing and haptic feedback:
    haptics.stopAudioProcessing()

 4. Release resources at the appropriate time:
    deinit {
        haptics.stopAudioProcessing()
    }
 */

import SwiftUI
import AVFoundation
import Accelerate
import CoreHaptics

class ECWavingHaptics {
    private var engine: CHHapticEngine?
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private var fftMagnitudes: [Float] = []
    private var isPlaying = false
    private var wasPlayingBeforeBackground = false
    
    private var minFrequency: Float
    private var maxFrequency: Float
    private var isLooping: Bool
    private var playCallback: (() -> Void)?
    private var stopCallback: (() -> Void)?
    private var errorCallback: ((Error) -> Void)?
    
    init(audioFileURL: URL, audioFormat: AVAudioFormat, minFrequency: Float, maxFrequency: Float, isLooping: Bool, playCallback: (() -> Void)? = nil, stopCallback: (() -> Void)? = nil, errorCallback: ((Error) -> Void)? = nil) {
        self.minFrequency = minFrequency
        self.maxFrequency = maxFrequency
        self.isLooping = isLooping
        self.playCallback = playCallback
        self.stopCallback = stopCallback
        self.errorCallback = errorCallback
        
        setupHaptics()
        setupAudioPlayer(audioFileURL: audioFileURL, audioFormat: audioFormat)
        setupNotifications()
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // 添加引擎重启回调
            engine?.stoppedHandler = { [weak self] reason in
                print("引擎停止，原因：\(reason)")
                self?.restartHapticEngine()
            }
        } catch {
            errorCallback?(error)
        }
    }
    
    private func restartHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            try engine?.start()
            print("触觉引擎重新启动成功")
        } catch {
            print("触觉引擎重新启动失败：\(error)")
            errorCallback?(error)
        }
    }
    
    private func setupAudioPlayer(audioFileURL: URL, audioFormat: AVAudioFormat) {
        do {
            audioFile = try AVAudioFile(forReading: audioFileURL, commonFormat: audioFormat.commonFormat, interleaved: audioFormat.isInterleaved)
        } catch {
            errorCallback?(error)
        }
    }
    
    func startAudioProcessing() {
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        guard let audioEngine = audioEngine, let audioPlayerNode = audioPlayerNode, let audioFile = audioFile else { return }
        
        audioEngine.attach(audioPlayerNode)
        
        let mixer = audioEngine.mainMixerNode
        audioEngine.connect(audioPlayerNode, to: mixer, format: audioFile.processingFormat)
        
        let tapNode = mixer
        let format = tapNode.outputFormat(forBus: 0)
        
        tapNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.processBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            scheduleBuffer()
            isPlaying = true
            playCallback?()
        } catch {
            errorCallback?(error)
        }
    }
    
    private func scheduleBuffer() {
        guard let audioFile = audioFile, let audioPlayerNode = audioPlayerNode else { return }
        
        audioPlayerNode.scheduleFile(audioFile, at: nil) { [weak self] in
            guard let self = self else { return }
            if self.isLooping {
                self.scheduleBuffer()
            } else {
                self.stopAudioProcessing()
            }
        }
        audioPlayerNode.play()
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        var realParts = [Float](repeating: 0, count: frameCount / 2)
        var imaginaryParts = [Float](repeating: 0, count: frameCount / 2)
        
        realParts.withUnsafeMutableBufferPointer { realPointer in
            imaginaryParts.withUnsafeMutableBufferPointer { imagPointer in
                var splitComplex = DSPSplitComplex(realp: realPointer.baseAddress!, imagp: imagPointer.baseAddress!)

                let log2n = UInt(round(log2(Float(frameCount))))
                let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2n), FFTRadix(kFFTRadix2))!

                channelData.withMemoryRebound(to: DSPComplex.self, capacity: frameCount) { typeConvertedTransferBuffer in
                    vDSP_ctoz(typeConvertedTransferBuffer, 2, &splitComplex, 1, vDSP_Length(frameCount / 2))
                }

                vDSP_fft_zrip(fftSetup, &splitComplex, 1, vDSP_Length(log2n), FFTDirection(FFT_FORWARD))
                vDSP_destroy_fftsetup(fftSetup)

                fftMagnitudes = [Float](repeating: 0.0, count: frameCount / 2)
                vDSP_zvmags(&splitComplex, 1, &fftMagnitudes, 1, vDSP_Length(frameCount / 2))
            }
        }

        let minBin = Int(minFrequency / (Float(buffer.format.sampleRate) / Float(frameCount)))
        let maxBin = Int(maxFrequency / (Float(buffer.format.sampleRate) / Float(frameCount)))

        let relevantMagnitudes = Array(fftMagnitudes[minBin..<maxBin])
        let maxMagnitude = relevantMagnitudes.max() ?? 0

        let normalizedIntensity = Float(maxMagnitude) / Float(frameCount)
        triggerHapticFeedback(intensity: normalizedIntensity)
    }
    
    private func triggerHapticFeedback(intensity: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }
        
        let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensityParameter, sharpnessParameter], relativeTime: 0, duration: 0.1)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("触发触觉反馈失败：\(error)")
            errorCallback?(error)
        }
    }
    
    func stopAudioProcessing() {
        guard let audioEngine = audioEngine, let audioPlayerNode = audioPlayerNode else { return }
        
        if isPlaying {
            audioPlayerNode.stop()
            audioEngine.mainMixerNode.removeTap(onBus: 0)
            audioEngine.stop()
            isPlaying = false
            
            self.audioEngine = nil
            self.audioPlayerNode = nil
            
            stopCallback?()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.wasPlayingBeforeBackground = self?.isPlaying ?? false
            self?.stopAudioProcessing()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            if self?.wasPlayingBeforeBackground == true {
                self?.restartHapticEngine()
                self?.startAudioProcessing()
            }
        }
    }
}
