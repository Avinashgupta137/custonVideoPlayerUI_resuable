//
//  ContentView.swift
//  CustomVideoPlayer
//
//  Created by AVINASH IOS Dev on 05/03/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            VideoPlayerManager(url: URL(string: "https://d26idhjf0y1p2g.cloudfront.net/out/v1/cd66dd25b9774cb29943bab54bbf3e2f/index.m3u8")!, size: size, safeArea: safeArea)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.light)
    }
}

