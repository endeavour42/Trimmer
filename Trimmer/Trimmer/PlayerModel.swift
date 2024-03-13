//
//  PlayerModel.swift
//  Trimmer
//
//  Created by endeavour42 on 13/03/2024.
//

import AVFoundation
import SwiftUI

protocol PlayerModelSubscriber {
    func modelChanged()
}

class PlayerModel: ObservableObject {
    private (set) var player = AVPlayer()
    private var currentlySeeking = false
    private var pendingTime: Double?
    private let changedNotification = Notification.Name("playerModelChanged")
    private (set) var waterMarkImages: [CGImage] = []
    private (set) var waterMarkDurations: [Double] = []

    private var asset: AVAsset? {
        didSet {
            player.replaceCurrentItem(with: asset != nil ? .init(asset: asset!) : nil)
            duration = asset?.duration.seconds ?? 0
            minTime = 0
            maxTime = asset?.duration.seconds ?? 0
            seek(to: 0)
        }
    }
    
    func subscribe(_ observer: PlayerModelSubscriber) {
        NotificationCenter.default.addObserver(forName: changedNotification, object: nil, queue: nil) { _ in
            observer.modelChanged()
        }
    }
    func unsubscribe(_ observer: PlayerModelSubscriber) {
        NotificationCenter.default.removeObserver(observer, name: changedNotification, object: nil)
    }
    private func notifyChange() {
        NotificationCenter.default.post(name: changedNotification, object: self)
    }

    init() {
        setup()
    }
    
    private func setup() {
        
        // watermark
        let data = try! Data(contentsOf: Bundle.main.url(forResource: "jump-hello.gif", withExtension: nil)!)
        let imageSource = CGImageSourceCreateWithData(data as! CFData, nil)!
        let count = CGImageSourceGetCount(imageSource)
        waterMarkImages = (0 ..< count).map { i in
            CGImageSourceCreateImageAtIndex(imageSource, i, nil)!
        }
        // TODO: calculate durations properly
        waterMarkDurations = (0 ..< count).map { _ in 0.1 }
        
        //let url = URL(string: "https://www.pexels.com/download/video/1722591/")!
        let url = Bundle.main.url(forResource: "pexels_videos_1722591 (1080p).mp4", withExtension: nil)!
        asset = AVAsset(url: url)

        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 1000), queue: nil) { time in
            withAnimation {
                if !self.currentlySeeking {
                    self.currentTime = time.seconds
                }
            }
        }
    }
    
    @Published var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                player.play()
            } else {
                player.pause()
            }
            notifyChange()
        }
    }
    @Published private (set) var currentTime: Double = 0 {
        didSet { notifyChange() }
    }
    @Published var minTime: Double = 0 {
        didSet {
            isPlaying = false
            seek(to: minTime)
            notifyChange()
        }
    }
    @Published var maxTime: Double = 0 {
        didSet {
            isPlaying = false
            seek(to: maxTime)
            notifyChange()
        }
    }
    @Published private (set) var duration: Double = 0 {
        didSet { notifyChange() }
    }
    @Published var showWatermark: Bool = false {
        didSet { notifyChange() }
    }

    func seek(to time: Double) {
        if !currentlySeeking {
            currentlySeeking = true
            player.currentItem?.seek(to: CMTime(seconds: time, preferredTimescale: 1000)) { done in
                self.currentlySeeking = false
                if let pendingTime = self.pendingTime {
                    self.pendingTime = nil
                    self.seek(to: pendingTime)
                }
            }
        } else {
            pendingTime = time
        }
    }
    
    func trim() {
        isPlaying = false
        let composition = AVMutableComposition()
        let min = CMTime(seconds: minTime, preferredTimescale: 1000)
        let max = CMTime(seconds: maxTime, preferredTimescale: 1000)
        let insertionPoint = CMTime.zero
        
        if let track = asset?.tracks(withMediaType: .video).first {
            let newTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
            try! newTrack.insertTimeRange(.init(start: min, end: max), of: track, at: insertionPoint)
        }
        if let track = asset?.tracks(withMediaType: .audio).first {
            let newTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
            try! newTrack.insertTimeRange(.init(start: min, end: max), of: track, at: insertionPoint)
        }
        asset = composition
    }
}
