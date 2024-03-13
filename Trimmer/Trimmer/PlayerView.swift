//
//  PlayerView.swift
//  Trimmer
//
//  Created by endeavour42 on 13/03/2024.
//

import AVFoundation
import UIKit
import SwiftUI

class UiPlayerView: UIView {
    var model: PlayerModel? {
        didSet {
            oldValue?.unsubscribe(self)
            model?.subscribe(self)
            playerLayer.player = model?.player
        }
    }

    private var watermarkLayer: CALayer?
    private var showingWatermark: Bool { watermarkLayer != nil }
    
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    private func showWatermark(images: [CGImage], durations: [Double]) {
        let size = bounds.size
        let watermarkLayer = CALayer()
        self.watermarkLayer = watermarkLayer
        watermarkLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        watermarkLayer.opacity = 0.5
        watermarkLayer.isOpaque = false
        
        let sublayer = CALayer()
        sublayer.contents = nil
        sublayer.shadowOpacity = 0.5
        sublayer.bounds = CGRectMake(0, 0, size.width/2, size.height/2)
        sublayer.position = CGPoint(x: watermarkLayer.bounds.size.width/4, y: watermarkLayer.bounds.size.height/4);
        watermarkLayer.addSublayer(sublayer)
        
        let totalDuration = durations.reduce(0, +)
        let a = CAKeyframeAnimation(keyPath: "contents")
        a.values = images
        // TODO: calculate durations properly
        a.keyTimes = (0 ..< durations.count).map { i in NSNumber(floatLiteral: Double(i) / Double(durations.count)) }
        a.duration = totalDuration
        a.repeatCount = .infinity
        a.autoreverses = true
        
        sublayer.add(a, forKey: "xx")
        
        watermarkLayer.position = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        layer.addSublayer(watermarkLayer)
    }
    
    private func hideWatermark() {
        watermarkLayer?.removeFromSuperlayer()
        watermarkLayer = nil
    }
}

extension UiPlayerView: PlayerModelSubscriber {
    func modelChanged() {
        if showingWatermark != model?.showWatermark {
            if let model, model.showWatermark {
                showWatermark(images: model.waterMarkImages, durations: model.waterMarkDurations)
            } else {
                hideWatermark()
            }
        }
    }
}

struct PlayerView: UIViewRepresentable {
    let model: PlayerModel
    
    func makeUIView(context: Context) -> UiPlayerView {
        let view = UiPlayerView()
        view.model = model
        return view
    }
    func updateUIView(_ view: UiPlayerView, context: Context) {
        view.model = model
    }
}
