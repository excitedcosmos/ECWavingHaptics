# ECWavingHaptics

## 特征和特性

1. **结合音频处理和触觉反馈**，提供实时的音频可感知化体验
2. **支持自定义音频文件和频率范围**
3. **提供循环播放选项**
4. **实现了后台暂停和前台恢复功能**
5. **使用 Core Haptics 框架**提供触觉反馈
6. **利用 Accelerate 框架**进行高效的 FFT 计算

## 注意事项

1. 需要 **iOS 13.0** 或更高版本，因为使用了 Core Haptics 框架
2. 触觉反馈依赖于设备硬件支持，部分设备可能不支持
3. 音频处理可能会增加设备的电池消耗
4. 大文件或高采样率的音频可能会影响性能

## 使用方法

### Swift Package Manager

```swift
.package(url: "https://github.com/excitedcosmos/ECWavingHaptics.git", from: "1.0.0")
```
或者
```swift
https://github.com/excitedcosmos/ECWavingHaptics.git
```

### 创建 `ECWavingHaptics` 实例

```swift
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
```

**参数说明**：

- `audioFileURL`: 音频文件的 URL
- `audioFormat`: 音频格式，包括采样率和通道数
- `minFrequency`: 最小频率，单位为 Hz
- `maxFrequency`: 最大频率，单位为 Hz
- `isLooping`: 是否循环播放
- `playCallback`: 开始播放时的回调函数
- `stopCallback`: 停止播放时的回调函数
- `errorCallback`: 发生错误时的回调函数

### 开始音频处理和触觉反馈

```swift
haptics.startAudioProcessing()
```

### 停止音频处理和触觉反馈

```swift
haptics.stopAudioProcessing()
```

### 在适当的时机释放资源

```swift
deinit {
    haptics.stopAudioProcessing()
}
```

## ECWavingHaptics Class

### Features and Characteristics

1. **Combines audio processing and haptic feedback** to provide real-time audio sensorization experience
2. **Supports custom audio files and frequency ranges**
3. **Offers looping playback option**
4. **Implements background pause and foreground resume functionality**
5. **Uses Core Haptics framework** for haptic feedback
6. **Utilizes Accelerate framework** for efficient FFT calculations

### Notes

1. Requires **iOS 13.0** or higher due to the use of Core Haptics framework
2. Haptic feedback depends on device hardware support, some devices may not support it
3. Audio processing may increase device battery consumption
4. Large files or high sample rate audio may affect performance

### Usage

1. Create an `ECWavingHaptics` instance:

    ```swift
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
    ```

    **Parameter description**:
    
    - `audioFileURL`: URL of the audio file
    - `audioFormat`: Audio format, including sample rate and number of channels
    - `minFrequency`: Minimum frequency in Hz
    - `maxFrequency`: Maximum frequency in Hz
    - `isLooping`: Whether to loop playback
    - `playCallback`: Callback function when playback starts
    - `stopCallback`: Callback function when playback stops
    - `errorCallback`: Callback function when an error occurs

2. Start audio processing and haptic feedback:

    ```swift
    haptics.startAudioProcessing()
    ```

3. Stop audio processing and haptic feedback:

    ```swift
    haptics.stopAudioProcessing()
    ```

4. Release resources at the appropriate time:

    ```swift
    deinit {
        haptics.stopAudioProcessing()
    }
    ```
