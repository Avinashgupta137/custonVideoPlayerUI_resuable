//
//  VideoOptionsPopup.swift
//  CustomVideoPlayer
//
//  Created by Sanskar IOS Dev on 15/09/25.
//

import SwiftUI
import AVKit
import UIKit

enum PopupMenu {
    case main
    case quality
    case speed
}

struct VideoOptionsPopup: View {
    @Binding var isVisible: Bool
    @Binding var selectedQuality: String
    @Binding var selectedSpeed: Double
    @Binding var showShareSheet: Bool
    var qualityOptions: [String]
    var applyQuality: (String) -> Void
    var applySpeed: (Double) -> Void
    
    @State private var currentMenu: PopupMenu = .main
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            switch currentMenu {
                
            case .main:
                Button {
                    showShareSheet = true
                    isVisible = false
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                        Spacer()
                    }
                }
                
                Button {
                    withAnimation { currentMenu = .quality }
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Quality")
                        Spacer()
                    }
                }
                
                Button {
                    withAnimation { currentMenu = .speed }
                } label: {
                    HStack {
                        Image(systemName: "speedometer")
                        Text("Playback speed")
                        Spacer()
                    }
                }
                
                Button {
                    withAnimation { isVisible = false }
                } label: {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Cancel")
                        Spacer()
                    }
                }
                
            case .quality:
                Text("Quality").bold()
                ForEach(qualityOptions, id: \.self) { quality in
                    Button(action: {
                        selectedQuality = quality
                        applyQuality(quality)
                        isVisible = false
                    }) {
                        HStack {
                            Text(quality)
                            if selectedQuality == quality {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                Button("Back") {
                    withAnimation { currentMenu = .main }
                }
                
            case .speed:
                Text("Playback Speed")
                    .font(.headline)
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { speed in
                    Button {
                        selectedSpeed = speed
                        applySpeed(speed)
                        withAnimation { isVisible = false }
                    } label: {
                        HStack {
                            Text("\(speed, specifier: "%.1fx")")
                            Spacer()
                            if selectedSpeed == speed {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Button("Back") {
                    withAnimation { currentMenu = .main }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
        .frame(maxWidth: 250, alignment: .topTrailing)
        .foregroundColor(.white)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}


struct HLSVariant {
    let resolution: String?
    let bandwidth: Double
}

func fetchHLSVariants(from url: URL, completion: @escaping ([HLSVariant]) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        guard let data = data, let playlist = String(data: data, encoding: .utf8) else {
            completion([])
            return
        }
        
        var variants: [HLSVariant] = []
        
        let lines = playlist.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("EXT-X-STREAM-INF") {
                let resolution = line.slice(from: "RESOLUTION=", to: ",")
                let bandwidthStr = line.slice(from: "BANDWIDTH=", to: ",") ?? line.slice(from: "BANDWIDTH=", to: "")
                if let bwStr = bandwidthStr, let bw = Double(bwStr) {
                    variants.append(HLSVariant(resolution: resolution, bandwidth: bw))
                }
            }
        }
        
        completion(variants)
    }.resume()
}

extension String {
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { start in
            (range(of: to, range: start..<endIndex)?.lowerBound).map { end in
                String(self[start..<end])
            }
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
