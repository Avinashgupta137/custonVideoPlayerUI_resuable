//
//  VideoPlayerManager.swift
//  CustomVideoPlayer
//
//  Created by AVINASH IOS Dev on 05/03/25.
//
//https://sanskartv.pc.cdn.bitgravity.com/vod-output/shree_ram_katha/kirit_bhai_ji_maharaj/kiritbhaiji_shrisita_charitra_ratlam_mp_day_four/master.m3u8

//https://d26idhjf0y1p2g.cloudfront.net/out/v1/cd66dd25b9774cb29943bab54bbf3e2f/index.m3u8

//https://bhaktiappproduction.s3.ap-south-1.amazonaws.com/premium_videos/promo_videos/3080535BDS_Bhaktmal_Katha_Jagannathpuri%2C_Odisha_11_Jan_2025_Promo.mp4
import SwiftUI
import AVKit
import Combine

struct VideoPlayerManager: View {
    
    let url: URL
    var size : CGSize
    var safeArea: EdgeInsets
    ///View Properties
    //    @State private var player: AVPlayer? = {
    //        let avPlayer = AVPlayer(url: self.url)
    //        avPlayer.automaticallyWaitsToMinimizeStalling = false
    //        avPlayer.currentItem?.preferredForwardBufferDuration = 1
    //        return avPlayer
    //    }()
    
    init(url: URL, size: CGSize, safeArea: EdgeInsets) {
        self.url = url
        self.size = size
        self.safeArea = safeArea
        _player = State(initialValue: AVPlayer(url: url)) // ✅ Initialize here
    }
    @State private var player: AVPlayer?
    
    @State private var showPlayerControlls : Bool = false
    @State private var isPlaying : Bool = false
    @State private var timeoutTask : DispatchWorkItem?
    @State private var isFinishedPlaying : Bool = false
    /// Videi Seekar
    @GestureState private var isDragging : Bool = false
    @State private var isSeeking : Bool = false
    @State private var progress : CGFloat = 0
    @State private var isObserverAdded : Bool = false
    @State private var isRotated : Bool = false
    @State private var isMuted: Bool = false
    
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isBuffering = true
    
    @State private var showOptionsPopup: Bool = false
    @State private var selectedQuality: String = "Auto"
    @State private var selectedSpeed: Double = 1.0
    @State private var showShareSheet: Bool = false
    
    @State private var hlsVariants: [HLSVariant] = []
    
    private var availableQualities: [String] {
        var qualities: [String] = ["Auto"]
        for variant in hlsVariants {
            if let res = variant.resolution {
                qualities.append(res)
            } else {
                if variant.bandwidth < 500_000 {
                    qualities.append("216p")
                } else if variant.bandwidth < 900_000 {
                    qualities.append("360p")
                } else if variant.bandwidth < 1_500_000 {
                    qualities.append("504p")
                } else {
                    qualities.append("720p")
                }
            }
        }
        var seen = Set<String>()
        return qualities.filter { seen.insert($0).inserted }
    }
    
    var body: some View {
        VStack {
            let videoPlayerSize: CGSize = isRotated
            ? .init(width: size.height, height: size.width)
            : .init(width: size.width, height: size.height / 3.5)
            
            ZStack {
                if let player {
                    CustomVideoPlayer(player: player)
                    
                        .overlay {
                            Rectangle()
                                .fill(.black.opacity(0.4))
                                .opacity(showPlayerControlls || isDragging ? 1 : 0)
                                .animation(.easeInOut(duration: 0.35), value: isDragging)
                                .overlay {
                                    PlayerBackControls()
                                }
                        }
                        .overlay(content: {
                            HStack(spacing: 60) {
                                DoubleTapSeek {
                                    let seconds = player.currentTime().seconds - 15
                                    player.seek(to: .init(seconds: seconds, preferredTimescale: 600))
                                }
                                DoubleTapSeek(isForward: true) {
                                    let seconds = player.currentTime().seconds + 15
                                    player.seek(to: .init(seconds: seconds, preferredTimescale: 600))
                                }
                            }
                        })
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showPlayerControlls.toggle()
                            }
                            if showPlayerControlls && isPlaying {
                                timeOutControls()
                            }
                        }
                        .overlay(alignment : .bottom) {
                            videoSeekerView(videoPlayerSize)
                                .offset(y: isRotated ? -15 : 0)
                        }
                    
                    VStack {
                        HStack (spacing: 1) {
                            Spacer()
                            Button(action: {
                                isMuted.toggle()
                                player.isMuted = isMuted
                            }) {
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 5)
                            
                            Button(action: {
                                // TODO: Add menu action
                                withAnimation {
                                    showOptionsPopup.toggle()
                                }
                            }) {
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .rotationEffect(.degrees(90))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 5)
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isRotated.toggle()
                                }
                            }) {
                                Image(systemName: isRotated ? "arrow.down.right.and.arrow.up.left" :  "arrow.down.left.and.arrow.up.right")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                    .padding(.trailing, 15)
                                    .padding(.bottom, 10)
                            }
                        }
                    }
                    .opacity(showPlayerControlls ? 1 : 0)
                }
                if isBuffering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                }
                
                if showOptionsPopup {
                    VideoOptionsPopup(
                        isVisible: $showOptionsPopup,
                        selectedQuality: $selectedQuality,
                        selectedSpeed: $selectedSpeed,
                        showShareSheet: $showShareSheet,
                        qualityOptions: availableQualities, // ✅ dynamic
                        applyQuality: { quality in
                            applyQuality(quality)
                        },
                        applySpeed: { speed in
                            player?.rate = Float(speed)
                        }
                    )
                    .frame(maxWidth: 250)
                    .padding(.top, 20)
                    .padding(.trailing, 0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(2) // ensure it stays on top
                    .animation(.easeInOut, value: showOptionsPopup)
                    .frame(maxWidth: isRotated ? size.height : size.width,
                           maxHeight: isRotated ? size.width : size.height / 3.5, alignment: .topTrailing)
                }
                
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = player?.currentItem?.asset as? AVURLAsset {
                    ActivityView(activityItems: [url.url])
                }
            }
            .background(content: {
                Rectangle()
                    .fill(.black)
                    .padding(.trailing, isRotated ? -safeArea.bottom : 0)
                    .padding(.leading, isRotated ? -safeArea.top : 0)
                
            })
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if -value.translation.height > 100 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRotated = true
                            }
                        }else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRotated = false
                            }
                        }
                    }
            )
            
            .frame(width: isRotated ? size.height : size.width,
                   height: isRotated ? size.width : size.height / 3.5)
            .background(Color.black.ignoresSafeArea(isRotated ? .all : []))
            
            .rotationEffect(.degrees(isRotated ? 90 : 0), anchor: .center)
            .offset(x: isRotated ? (size.width / 2) - (size.height / 2) : 0,
                    y: isRotated ? (size.height / 2) - (size.width / 2) : 0)
            .animation(.easeInOut, value: isRotated)
            .zIndex(10000)
            Spacer()
        }
        .padding(.top , safeArea.top)
        .onAppear {
            setupPlayerObservers()
            
            fetchHLSVariants(from: url) { variants in
                DispatchQueue.main.async {
                    hlsVariants = variants
                    print("✅ Loaded HLS variants: \(variants)")
                }
                
            }
        }
        .onAppear {
            if player == nil { // only setup once
                let avPlayer = AVPlayer(url: url)
                avPlayer.automaticallyWaitsToMinimizeStalling = false
                avPlayer.currentItem?.preferredForwardBufferDuration = 1
                player = avPlayer
                player?.play()
            }
        }
        .onDisappear {
            cancellables.removeAll()
            timeoutTask?.cancel()
        }
        
    }
    
    
    private func setupPlayerObservers() {
        guard !isObserverAdded else { return }
        
        // Track player progress
        player?.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main) { _ in
            guard let currentItem = player?.currentItem else { return }
            
            if currentItem.duration.isIndefinite {
                progress = 0
            } else {
                let currentTime = player?.currentTime().seconds ?? 0
                let total = currentItem.duration.seconds
                if !isSeeking { progress = currentTime / total }
                if progress >= 1 {
                    isFinishedPlaying = true
                    isPlaying = false
                }
            }
        }
        
        // Observe buffering start/stop
        player?.currentItem?.publisher(for: \.isPlaybackBufferEmpty)
            .receive(on: RunLoop.main)
            .sink { empty in
                isBuffering = empty
                if empty { player?.pause() }
            }
            .store(in: &cancellables)
        
        player?.currentItem?.publisher(for: \.isPlaybackLikelyToKeepUp)
            .receive(on: RunLoop.main)
            .sink { keepUp in
                isBuffering = !keepUp
                if keepUp && !isFinishedPlaying {
                    player?.play()   // auto resume
                    isPlaying = true
                }
            }
            .store(in: &cancellables)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemPlaybackStalled,
                                               object: player?.currentItem,
                                               queue: .main) { _ in
            isBuffering = true
        }
        isObserverAdded = true
    }
    
    @ViewBuilder func videoSeekerView(_ videoSize: CGSize) -> some View {
        if let item = player?.currentItem, item.duration.isIndefinite {
            VStack(alignment: .leading, spacing: 5) {
                // LIVE label
                HStack {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("LIVE")
                        .foregroundColor(.red)
                        .bold()
                }
                
                // Full-width live progress bar
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                    Rectangle()
                        .fill(Color.red)
                    GeometryReader { geo in
                        Circle()
                            .fill(Color.red)
                            .frame(width: 15, height: 15)
                            .position(x: geo.size.width, y: geo.size.height / 2)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 20)
                
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        } else if let currentItem = player?.currentItem{
            let totalDuration = currentItem.duration.seconds
            let playedDuration = totalDuration * progress
            let videoPlaySize = videoSize.width - 150
            HStack (spacing: 5){
                Text(formatTime(seconds: playedDuration))
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.gray)
                    Rectangle()
                        .fill(.red)
                        .frame(width: max(videoPlaySize * progress, 0))
                }
                .frame(height: 3)
                .overlay(alignment: .leading) {
                    Circle()
                        .fill(.red)
                        .frame(width: 15, height: 15)
                        .scaleEffect(showPlayerControlls || isDragging ? 1 : 0.001,
                                     anchor: progress * videoPlaySize > 15 ? .trailing : .leading)
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                        .offset(x: videoPlaySize * progress)
                        .gesture(
                            DragGesture()
                                .updating($isDragging, body: { _, out, _ in
                                    out = true
                                })
                                .onChanged { value in
                                    if let timeoutTask { timeoutTask.cancel() }
                                    let locationX = value.location.x
                                    let calculatedProgress = locationX / videoPlaySize
                                    
                                    progress = max(min(calculatedProgress, 1), 0)
                                    isSeeking = true
                                }
                                .onEnded { _ in
                                    if let currentPlayerItem = player?.currentItem {
                                        let totalDuration = currentPlayerItem.duration.seconds
                                        
                                        let seekTime = totalDuration * progress
                                        player?.seek(to: .init(seconds: seekTime, preferredTimescale: 600))
                                        
                                        if isPlaying {
                                            timeOutControls()
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            isSeeking = false
                                        }
                                    }
                                }
                        )
                        .padding(.horizontal, 10)
                        .offset(x: progress * videoPlaySize > 15 ? -15 : 0)
                        .frame(width: 15, height: 15)
                }
                Spacer()
                Text(formatTime(seconds: totalDuration))
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
        }
    }
    
    
    @ViewBuilder func PlayerBackControls() -> some View {
        HStack(spacing: 20) {
            Button {
                
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .fontWeight(.ultraLight)
                    .foregroundColor(.white)
                    .padding(15)
                    .background {
                        Circle()
                            .fill(.black.opacity(0.35))
                    }
            }
            .disabled(true)
            .opacity(0.6)
            Button {
                if isFinishedPlaying {
                    isFinishedPlaying = false
                    player?.seek(to: .zero)
                    progress = .zero
                }
                
                if isPlaying {
                    player?.pause()
                    if let timeoutTask {
                        timeoutTask.cancel()
                    }
                }else {
                    player?.play()
                    timeOutControls()
                }
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPlaying.toggle()
                }
            } label: {
                
                Image(systemName: isFinishedPlaying  ? "arrow.clockwise" : (isPlaying ? "pause.fill" : "play.fill"))
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(15)
                    .background {
                        Circle()
                            .fill(.black.opacity(0.35))
                    }
            }
            .scaleEffect(1.1)
            
            Button {
                
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .fontWeight(.ultraLight)
                    .foregroundColor(.white)
                    .padding(15)
                    .background {
                        Circle()
                            .fill(.black.opacity(0.35))
                    }
            }
            .disabled(true)
            .opacity(0.6)
        }
        .opacity(showPlayerControlls ? 1 : 0)
        .animation(.easeInOut(duration: 0.2),value: showPlayerControlls && !isDragging)
    }
    func timeOutControls() {
        timeoutTask?.cancel()
        
        timeoutTask = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.35)) {
                showPlayerControlls = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timeoutTask!)
    }
    private func applyQuality(_ quality: String) {
        selectedQuality = quality
        guard let player = player else { return }
        
        if quality == "Auto" {
            player.currentItem?.preferredPeakBitRate = 0
        } else {
            if let variant = hlsVariants.first(where: { v in
                if let res = v.resolution {
                    return res == quality
                }
                return false
            }) {
                player.currentItem?.preferredPeakBitRate = variant.bandwidth
            }
        }
        
        if isPlaying {
            player.play()
        }
    }
    
}
