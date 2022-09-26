//
//  MNPlayer.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/25.
//  播放器

import UIKit
import Foundation
import AudioToolbox
import AVFoundation
import ObjectiveC.runtime

@objc protocol MNPlayerDelegate: NSObjectProtocol {
    @objc optional func player(didEndDecode player: MNPlayer) -> Void
    @objc optional func player(didPlayTimeInterval player: MNPlayer) -> Void
    @objc optional func player(didChangeState player: MNPlayer) -> Void
    @objc optional func player(didPlayToEndTime player: MNPlayer) -> Void
    @objc optional func player(didLoadTimeRanges player: MNPlayer) -> Void
    @objc optional func player(likelyBufferEmpty player: MNPlayer) -> Void
    @objc optional func player(likelyToKeepUp player: MNPlayer) -> Void
    @objc optional func player(didChangePlayItem player: MNPlayer) -> Void
    @objc optional func player(_ player: MNPlayer, didPlayFailure error: Error) -> Void
    @objc optional func player(shouldPlayNextItem player: MNPlayer) -> Bool
    @objc optional func player(shouldStartPlaying player: MNPlayer) -> Bool
}

class MNPlayer: NSObject {
    
    enum PlayState: Int {
        case unknown, failed, playing, pause, finished
    }
    
    /**显示层AVPlayerLayer*/
    var layer: CALayer? {
        willSet {
            guard let layer = layer as? AVPlayerLayer else { return }
            layer.player = nil
        }
        didSet {
            guard let layer = layer as? AVPlayerLayer else { return }
            //layer.videoGravity = .resize
            layer.player = player
        }
    }
    /**当前状态*/
    private(set) var state: PlayState = .unknown {
        didSet {
            delegate?.player?(didChangeState: self)
        }
    }
    /**是否在播放*/
    var isPlaying: Bool { state == .playing }
    /**错误信息*/
    var error: Error? {
        if let error = player.error {
            return AVError.playError(.underlyingError(error))
        }
        if let error = player.currentItem?.error {
            return AVError.playError(.underlyingError(error))
        }
        return nil
    }
    /**当前播放地址*/
    var url: URL? {
        guard let _ = player.currentItem else { return nil }
        return urls[playIndex]
    }
    /**当前播放索引*/
    private(set) var playIndex: Int = 0
    /**当前播放的实例*/
    var playItem: AVPlayerItem? { player.currentItem }
    /**语音会话类型*/
    var sessionCategory: AVAudioSession.Category {
        isPlaybackEnabled ? .playback : .ambient
    }
    /**文件时长*/
    var duration: TimeInterval {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else { return 0.0 }
        return TimeInterval(CMTimeGetSeconds(currentItem.duration))
    }
    /**当前播放时长*/
    var timeInterval: TimeInterval {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else { return 0.0 }
        return TimeInterval(CMTimeGetSeconds(currentItem.currentTime()))
    }
    /**播放进度*/
    var progress: Float {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else { return 0.0 }
        if state == .finished { return 1.0 }
        let duration = CMTimeGetSeconds(currentItem.duration)
        let current = CMTimeGetSeconds(currentItem.currentTime())
        let progress = current/duration
        if progress.isNaN { return 0.0 }
        return Float(max(0.0, min(progress, 1.0)))
    }
    /**缓冲进度*/
    var buffer: Float {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else { return 0.0 }
        let ranges = currentItem.loadedTimeRanges
        guard ranges.count > 0 else { return 0.0 }
        let timeRange = ranges.last!.timeRangeValue
        let start = CMTimeGetSeconds(timeRange.start)
        let length = CMTimeGetSeconds(timeRange.duration)
        let total = start + length
        let duration = CMTimeGetSeconds(currentItem.duration)
        let progress = Float(total/duration)
        if progress.isNaN { return 0.0 }
        return min(1.0, max(0.0, progress))
    }
    /**速率*/
    var rate: Float {
        get { player.rate }
        set { player.rate = newValue }
    }
    /**音量*/
    var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }
    /**是否允许使用缓存*/
    var isAllowsUsingCache: Bool = false
    /**是否支持后台播放*/
    var isPlaybackEnabled: Bool = false
    /**开始播放的起始位置 只可使用一次*/
    var beginTimeInterval: TimeInterval = 0.0
    /**是否应该恢复播放*/
    private var isShouldResume: Bool = false
    /**文件资源*/
    private var urls: [URL] = [URL]()
    /**当前播放器有多少条资源*/
    var count: Int { urls.count }
    /**播放实例的缓存*/
    private var items: [String:AVPlayerItem] = [String:AVPlayerItem]()
    /**内部播放器*/
    private let player: AVPlayer = AVPlayer()
    /**监听者*/
    private var observer: Any?
    /**代理*/
    weak var delegate: MNPlayerDelegate?
    /**监听周期*/
    var observeTime: CMTime = .zero {
        willSet {
            guard let observer = observer else { return }
            player.removeTimeObserver(observer)
            self.observer = nil
        }
        didSet {
            guard observeTime != .zero else { return }
            observer = player.addPeriodicTimeObserver(forInterval: observeTime, queue: DispatchQueue.main) { [weak self] time in
                guard let self = self else { return }
                self.delegate?.player?(didPlayTimeInterval: self)
            }
        }
    }
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(playToEndTime(notify:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorLogEntry(notify:)), name: .AVPlayerItemNewErrorLogEntry, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(failedToEndTime(notify:)), name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(silenceSecondaryAudioHint(notify:)), name: AVAudioSession.silenceSecondaryAudioHintNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(routeChange(notify:)), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruption(notify:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    deinit {
        layer = nil
        delegate = nil
        removeAll()
        if let observer = observer { player.removeTimeObserver(observer) }
        NotificationCenter.default.removeObserver(self)
    }
    
    convenience init(urls: [URL]) {
        self.init()
        for url in urls {
            guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else { continue }
            self.urls.append(url)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        if keyPath == "status" {
            let status = AVPlayerItem.Status(rawValue: change?[.newKey] as? Int ?? AVPlayerItem.Status.unknown.rawValue)
            switch status {
            case .readyToPlay:
                guard state == .unknown else { return }
                isShouldResume = false
                delegate?.player?(didEndDecode: self)
                let play: Bool = delegate?.player?(shouldStartPlaying: self) ?? true
                if play {
                    guard sessionActive() else {
                        fail(reason: .notActive(sessionCategory))
                        return
                    }
                    let seconds = beginTimeInterval
                    if seconds > 0.0 {
                        beginTimeInterval = 0.0
                        seek(toSeconds: seconds) { [weak self] _ in
                            guard let self = self else { return }
                            self.player.play()
                            self.state = .playing
                        }
                        return
                    }
                    player.play()
                    state = .playing
                } else {
                    player.pause()
                    state = .pause
                }
            case .failed:
                player.pause()
                fail(reason: .statusError(.failed))
            default:
                break
            }
        } else if keyPath == "loadedTimeRanges" {
            delegate?.player?(didLoadTimeRanges: self)
        } else if keyPath == "playbackBufferEmpty" {
            delegate?.player?(likelyBufferEmpty: self)
        } else if keyPath == "playbackLikelyToKeepUp" {
            delegate?.player?(likelyToKeepUp: self)
        }
    }
}

// MARK: - 播放/暂停
extension MNPlayer {
    func prepare() {
        guard playIndex < urls.count else { return }
        isShouldResume = false
        replaceCurrentItemWithNil()
        objc_sync_enter(self)
        let playerItem = playerItem(for: urls[playIndex])
        addObserver(with: playerItem)
        player.replaceCurrentItem(with: playerItem)
        objc_sync_exit(self)
        delegate?.player?(didChangePlayItem: self)
    }
    
    func playerItem(for url: URL) -> AVPlayerItem {
        let key = url.isFileURL ? url.path : url.absoluteString
        var playerItem: AVPlayerItem! = items[key]
        if let _ = playerItem { return playerItem }
        playerItem = AVPlayerItem(url: url)
        for track in playerItem.tracks {
            guard let assetTrack = track.assetTrack else { continue }
            if assetTrack.mediaType == .audio {
                track.isEnabled = true
            }
        }
        if isAllowsUsingCache, key.count > 0 { items[key] = playerItem }
        return playerItem
    }
    
    func pause() {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else { return }
        player.pause()
        state = .pause
    }
    
    func play() {
        guard isPlaying == false else { return }
        guard sessionActive() else {
            fail(reason: .notActive(sessionCategory))
            return
        }
        guard let currentItem = player.currentItem else {
            prepare()
            return
        }
        guard currentItem.status == .readyToPlay else { return }
        isShouldResume = false
        if state == .finished {
            seek(toProgress: 0.0) { [weak self] finish in
                guard finish, let self = self else { return }
                self.player.play()
                self.state = .playing
            }
        } else {
            player.play()
            state = .playing
        }
    }
    
    func forward() {
        guard urls.count > 1, playIndex > 0 else { return }
        playIndex -= 1
        prepare()
    }
    
    func playNext() {
        guard playIndex <= (urls.count - 2) else { return }
        playIndex += 1
        prepare()
    }
    
    func play(index: Int) {
        guard index < urls.count else { return }
        playIndex = index
        prepare()
    }
    
    func replay() {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else {
            prepare()
            return
        }
        guard sessionActive() else {
            fail(reason: .notActive(sessionCategory))
            return
        }
        isShouldResume = false
        if state == .playing { pause() }
        seek(toProgress: 0.0) { [weak self] finish in
            guard finish, let self = self else { return }
            self.player.play()
            self.state = .playing
        }
    }
    
    /// 更新播放地址
    /// - Parameters:
    ///   - url: 文件地址
    ///   - index: 索引
    func update(url: URL, index: Int) {
        guard index < urls.count else { return }
        let old = urls[index]
        let key = old.isFileURL ? old.path : old.absoluteString
        items.removeValue(forKey: key)
        urls.remove(at: index)
        urls.insert(url, at: index)
    }
}

// MARK: -
extension MNPlayer {
    
    func removeAll() {
        guard urls.count > 0 else { return }
        replaceCurrentItemWithNil()
        urls.removeAll()
        items.removeAll()
        playIndex = 0
        state = .unknown
    }
    
    func contains(_ url: URL) -> Bool {
        return self.urls.filter { $0.path == url.path || $0.absoluteString == url.absoluteString }.count > 0
    }
    
    func add(_ urls: [URL]) {
        for url in urls {
            guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else { continue }
            self.urls.append(url)
        }
    }
    
    func insert(_ url: URL, at index: Int) {
        guard index <= urls.count else { return }
        guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else { return }
        urls.insert(url, at: index)
    }
}

// MARK: - Seek
extension MNPlayer {
    
    func seek(toProgress progress: Float, completion: ((Bool)->Void)?) {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else {
            completion?(false)
            return
        }
        let time = CMTimeMultiplyByFloat64(currentItem.duration, multiplier: Float64(progress))
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: completion ?? { _ in })
    }
    
    func seek(toSeconds seconds: TimeInterval, completion: ((Bool)->Void)?) {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else {
            completion?(false)
            return
        }
        let time = CMTime(seconds: seconds, preferredTimescale: currentItem.duration.timescale)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: completion ?? { _ in })
    }
}

// MARK: - Notification
private extension MNPlayer {
    // 播放结束
    @objc func playToEndTime(notify: Notification) {
        guard let object = notify.object as? AVPlayerItem, let currentItem = player.currentItem else { return }
        guard object == currentItem else { return }
        let next: Bool = delegate?.player?(shouldPlayNextItem: self) ?? false
        if next {
            if playIndex >= (urls.count - 1) {
                // 不支持播放下一曲
                seek(toProgress: 0.0) { [weak self] finish in
                    guard let self = self else { return }
                    self.player.play()
                }
            } else {
                // 进度调整为开始部分, 避免播放上一曲时直接就是结束位置
                seek(toProgress: 0.0, completion: nil)
                playNext()
            }
        } else {
            state = .finished
            delegate?.player?(didPlayToEndTime: self)
        }
    }
    
    @objc func failedToEndTime(notify: Notification) {
        guard let object = notify.object as? AVPlayerItem, let currentItem = player.currentItem else { return }
        guard object == currentItem else { return }
        isShouldResume = false
        if let error = notify.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
            fail(error: .playError(.underlyingError(error)))
        } else {
            fail(reason: .custom(AVErrorUnknown, "播放失败"))
        }
    }
    
    @objc func errorLogEntry(notify: Notification) {
        guard let object = notify.object as? AVPlayerItem, let currentItem = player.currentItem else { return }
        guard object == currentItem else { return }
        isShouldResume = false
        fail(reason: .custom(AVErrorUnknown, "播放失败"))
    }
    
    // 其他App独占事件
    @objc func silenceSecondaryAudioHint(notify: Notification) {
        guard let userInfo = notify.userInfo, let typeValue = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt, let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: typeValue) else { return }
        if type == .begin {
            if state == .playing {
                pause()
                isShouldResume = true
            }
        } else if isShouldResume {
            play()
            isShouldResume = false
        }
    }
    
    // 耳机事件
    @objc func routeChange(notify: Notification) {
        guard let userInfo = notify.userInfo, let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt, let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        if reason == .oldDeviceUnavailable {
            // 旧设备不可用
            guard let route = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription, route.outputs.count > 0, let output = route.outputs.first else { return }
            if output.portType == .headphones {
                // 暂停播放
                if state == .playing {
                    pause()
                }
            }
        }
    }
    
    // 中断事件
    @objc func sessionInterruption(notify: Notification) {
        guard let userInfo = notify.userInfo, let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            if state == .playing {
                pause()
                isShouldResume = true
            }
        } else if isShouldResume {
            guard let optionValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionValue)
            if options == .shouldResume {
                play()
                isShouldResume = false
            }
        }
    }
}

// MARK: - Private
private extension MNPlayer {
    func fail(msg: String) {
        fail(reason: .custom(AVErrorUnknown, msg))
    }
    
    func fail(reason: AVError.PlayErrorReason) {
        fail(error: .playError(reason))
    }
    
    func fail(error: AVError) {
        state = .failed
        delegate?.player?(self, didPlayFailure: error)
    }
    
    private func sessionActive() -> Bool {
        let category: AVAudioSession.Category = .playAndRecord//isPlaybackEnabled ? .playback : .ambient
        if AVAudioSession.sharedInstance().category != category {
            do {
                try AVAudioSession.sharedInstance().setCategory(category)
            } catch {
                return false
            }
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            return false
        }
        return true
    }
    
    func replaceCurrentItemWithNil() {
        guard let currentItem = player.currentItem else { return }
        if currentItem.status == .readyToPlay { player.pause() }
        removeObserver(with: currentItem)
        player.replaceCurrentItem(with: nil)
        state = .unknown
        delegate?.player?(didPlayTimeInterval: self)
    }
    
    func addObserver(with playerItem: AVPlayerItem?) {
        guard let item = playerItem, item.isObserved == false else { return }
        item.isObserved = true
        item.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.old, .new], context: nil)
        item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.old, .new], context: nil)
        item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.old, .new], context: nil)
    }
    
    func removeObserver(with playerItem: AVPlayerItem?) {
        guard let item = playerItem, item.isObserved else { return }
        item.isObserved = false
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "loadedTimeRanges")
        item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }
}

// MARK: - 音效
extension MNPlayer {
    @objc static func playSound(path: String, shake: Bool) {
        guard FileManager.default.fileExists(atPath: path) else { return }
        var id: SystemSoundID = 0
        guard AudioServicesCreateSystemSoundID(URL(fileURLWithPath: path) as CFURL, &id) == noErr else { return }
        playSound(id: id, shake: shake)
    }
    
    @objc static func playSound(id: UInt32, shake: Bool) {
        guard AudioServicesAddSystemSoundCompletion(id, nil, nil, { _, _ in }, nil) == noErr else { return }
        if shake {
            AudioServicesPlayAlertSound(id)
        } else {
            AudioServicesPlaySystemSound(id)
        }
    }
}

private extension AVPlayerItem {
    struct AssociatedKey {
        static var isObserved = "com.mn.player.item.observed"
    }
    var isObserved: Bool {
        get {
            guard let result = objc_getAssociatedObject(self, AVPlayerItem.AssociatedKey.isObserved) as? Bool else { return false }
            return result
        }
        set {
            objc_setAssociatedObject(self, AVPlayerItem.AssociatedKey.isObserved, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}


