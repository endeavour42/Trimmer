//
//  ComboSlider.swift
//  Trimmer
//
//  Created by endeavour42 on 13/03/2024.
//

import UIKit
import SwiftUI

class UiSlider: UISlider {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let rect = thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
        if !rect.contains(point) { return nil }
        return super.hitTest(point, with: event)
    }
}

class UiComboSlider: UIView {
    var model: PlayerModel? {
        didSet {
            oldValue?.unsubscribe(self)
            model?.subscribe(self)
        }
    }
    private var minSlider: UISlider
    private var maxSlider: UISlider
    private var curSlider: UISlider

    override init(frame: CGRect) {
        minSlider = UiSlider(frame: frame)
        maxSlider = UiSlider(frame: frame)
        curSlider = UiSlider(frame: frame)
        super.init(frame: frame)
        minSlider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        maxSlider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        curSlider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        minSlider.minimumTrackTintColor = .lightGray
        minSlider.maximumTrackTintColor = .tintColor
        maxSlider.minimumTrackTintColor = .clear
        maxSlider.maximumTrackTintColor = .lightGray
        curSlider.minimumTrackTintColor = .clear
        curSlider.maximumTrackTintColor = .clear
        minSlider.setThumbImage(UIImage(systemName: "square.fill"), for: .normal)
        maxSlider.setThumbImage(UIImage(systemName: "square.fill"), for: .normal)
        // curSlider.setThumbImage(UIImage(systemName: "capsule.portrait.fill"), for: .normal)
        
        minSlider.addTarget(self, action: #selector(notifyMinValueChanged), for: .valueChanged)
        maxSlider.addTarget(self, action: #selector(notifyMaxValueChanged), for: .valueChanged)
        curSlider.addTarget(self, action: #selector(notifyCurValueChanged), for: .valueChanged)
        precondition(autoresizesSubviews)
        addSubview(minSlider)
        addSubview(maxSlider)
        addSubview(curSlider)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func notifyMinValueChanged() {
        model?.minTime = minValue
    }
    @objc private func notifyMaxValueChanged() {
        model?.maxTime = maxValue
    }
    @objc private func notifyCurValueChanged() {
        model?.seek(to: currentValue)
    }

    private var totalValue: Double {
        Double(curSlider.maximumValue)
    }
    private func changeTotalValue(_ newValue: Double, notify: Bool) {
        minSlider.minimumValue = 0
        minSlider.maximumValue = Float(newValue)
        maxSlider.minimumValue = 0
        maxSlider.maximumValue = Float(newValue)
        curSlider.minimumValue = 0
        curSlider.maximumValue = Float(newValue)
    }
    private var minValue: Double {
        Double(minSlider.value)
    }
    private func changeMinValue(_ newValue: Double, notify: Bool) {
        if minSlider.value == Float(newValue) { return }
        minSlider.value = Float(newValue)
        if notify { notifyCurValueChanged() }
    }
    private var maxValue: Double {
        Double(maxSlider.value)
    }
    private func changeMaxValue(_ newValue: Double, notify: Bool) {
        if maxSlider.value == Float(newValue) { return }
        maxSlider.value = Float(newValue)
        if notify { notifyCurValueChanged() }
    }
    private var currentValue: Double {
        Double(curSlider.value)
    }
    private func changeCurrentValue(_ newValue: Double, notify: Bool) {
        if curSlider.value == Float(newValue) { return }
        curSlider.value = Float(newValue)
        if notify { notifyCurValueChanged() }
    }
}

extension UiComboSlider: PlayerModelSubscriber {
    func modelChanged() {
        guard let model else { return }
        if totalValue != model.duration {
            changeTotalValue(model.duration, notify: false)
        }
        if minValue != model.minTime {
            changeMinValue(model.minTime, notify: false)
        }
        if maxValue != model.maxTime {
            changeMaxValue(model.maxTime, notify: false)
        }
        if currentValue != model.currentTime {
            changeCurrentValue(model.currentTime, notify: false)
        }
    }
}

struct ComboSlider: UIViewRepresentable {
    let model: PlayerModel
    
    func makeUIView(context: Context) -> UiComboSlider {
        let view = UiComboSlider()
        view.model = model
        return view
    }
    func updateUIView(_ view: UiComboSlider, context: Context) {
        view.model = model
    }
}
