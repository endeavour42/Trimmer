//
//  ContentView.swift
//  Trimmer
//
//  Created by endeavour42 on 13/03/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = PlayerModel()
    
    var body: some View {
        ZStack {
            // TODO: fullscreen
            PlayerView(model: model)
            VStack {
                Text("Video duration: \(String(format: "%.1f", model.duration))")
                    .foregroundColor(Color(uiColor: .tintColor))
                    .font(.title).bold()
                Spacer()
                ComboSlider(model: model).frame(height: 30)
            }
            Button {
                model.isPlaying.toggle()
            } label: {
                Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                    .font(.largeTitle)
                    .opacity(0.5)
                    .scaleEffect(CGSize(width: 3, height: 3))
                    .padding(100)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button(model.showWatermark ? "hide watermark" : "show watermark") {
                    model.showWatermark.toggle()
                }
                Button("trim \(String(format: "%.1f", model.maxTime - model.minTime))") {
                    model.trim()
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
