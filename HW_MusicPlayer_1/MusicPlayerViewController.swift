//
//  MusicPlayerViewController.swift
//  HW_MusicPlayer_1
//
//  Created by 曹家瑋 on 2023/7/25.
//

/*
 1.上一首、下一首音樂。
 2.預設：歌曲播完會接著播放下一首
 3.播放模式：隨機、重複同一首、依照歌單順序播放。
 4.音樂播放進度條會隨著當前音樂播放的時間。（addPeriodicTimeObserver運用學習）
 5.音樂進度條可以讓使用者調整。
 6.顯示當前音樂的進度時間。
 7.音量大小的切換。
 
 
 由於我在storyboard預設playAndPauseButton的樣式為”play.circle“，用來表示目前沒有音樂在播放。
 而播放音樂時就會在 playPauseButtonTapped 中透過AVplayer的timeControlStatus去切換為"pause.circle"。
 
 但是當我設置fowardButtonTapped、backwardButtonTapped時發現，如果載入畫面後都沒有播放直接點擊下一首音樂時，
 雖然音樂可以播放但卻無法去更新到playAndPauseButton的樣式，因此在 playSong(song: Song)的部分，我又加入了更新playAndPauseButton樣式的功能。
 */


// updateMusicProgress 與 addPeriodicTimeObserver 修正版，處理滑塊抖動問題。
import UIKit
import AVFoundation

// 定義音樂播放的 UIViewController
class MusicPlayerViewController: UIViewController {
    
    /// 背景
    @IBOutlet weak var backgroundImageView: UIImageView!
    /// 專輯名稱
    @IBOutlet weak var albumNameLabel: UILabel!
    /// 專輯封面
    @IBOutlet weak var coverImageView: UIImageView!
    /// 歌曲名稱
    @IBOutlet weak var songNameLabel: UILabel!
    /// 歌手名稱
    @IBOutlet weak var artistLabel: UILabel!
    
    /// 音樂進度條（用於追蹤當前音樂播放的時間進度以及可以滑動調整播放時間）
    @IBOutlet weak var musicProgressSlider: UISlider!
    /// 顯示該首音樂正在進行的時間
    @IBOutlet weak var musicCurrentTimeLabel: UILabel!
    /// 顯示該首音樂的完整時間
    @IBOutlet weak var musicTotalTimeLabel: UILabel!
    
    /// 播放以及暫停按鈕的Outlet
    @IBOutlet weak var playAndPauseButton: UIButton!
    
    /// 下一首
    @IBOutlet weak var fowardButton: UIButton!
    /// 上一首
    @IBOutlet weak var backwardButton: UIButton!
    
    /// 音量調整
    @IBOutlet weak var volumeSlider: UISlider!
    /// 顯示音量控制條的View
    @IBOutlet weak var volumeView: UIView!
    /// 音量按鈕顯示（隨著音量大小聲而變化圖示）
    @IBOutlet weak var volumeButton: UIButton!
    
    /// 初始化音樂播放器
    let soundPlayer = AVPlayer()
    
    /// 追蹤目前正在播放的歌曲
    var currentSong: Song?
    
    /// 跟蹤當前播放的歌曲索引
    var currentSongIndex = 0
    
    /// 記錄當前的播放模式，設置為初始模式
    var playMode: PlayMode = .sequential

    
    /// 建立歌曲清單
    var songs: [Song] = [
        Song(albumName: "歹勢好勢", songName: "踅夜市", artist: "拍謝少年", coverImage: UIImage(named: "歹勢好勢"), fileUrl: Bundle.main.url(forResource: "踅夜市", withExtension: "mp3")!),
        Song(albumName: "愛情的盡頭", songName: "Last Dance", artist: "伍佰", coverImage: UIImage(named: "愛情的盡頭"), fileUrl: Bundle.main.url(forResource: "Last dance", withExtension: "mp3")!),
        Song(albumName: "醜奴兒", songName: "大風吹", artist: "草東沒有派對", coverImage: UIImage(named: "醜奴兒"), fileUrl: Bundle.main.url(forResource: "大風吹", withExtension: "mp3")!),
        Song(albumName: "台北嘻哈故事", songName: "台北嘻哈故事之一", artist: "蛋堡", coverImage: UIImage(named: "台北嘻哈故事"), fileUrl: Bundle.main.url(forResource: "台北嘻哈故事 之一", withExtension: "mp3")!),
        Song(albumName: "GDN EXPRESS", songName: "Yesterday", artist: "國蛋 GorDoN", coverImage: UIImage(named: "GDN EXPRESS"), fileUrl: Bundle.main.url(forResource: "Yesterday", withExtension: "mp3")!),
        Song(albumName: "Ride On Time", songName: "RIDE ON TIME", artist: "山下 達郎", coverImage: UIImage(named: "Ride On Time Cover"), fileUrl: Bundle.main.url(forResource: "RIDE ON TIME", withExtension: "mp3")!),
        Song(albumName: "Midnight Pretenders", songName: "Midnight Pretenders", artist: "亜蘭 知子", coverImage: UIImage(named: "Midnight Pretenders Cover"), fileUrl: Bundle.main.url(forResource: "Midnight Pretenders", withExtension: "mp3")!)
    ]
    
    // 當 view 加載完成後執行
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 使用 addPeriodicTimeObserver 方法追蹤音樂播放進度，每秒觸發一次時間觀察者。當musicProgressSlider沒有被滑動時執行updateMusicProgress，避免更新滑塊導致抖動。
        soundPlayer.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .main) { time in
            // 檢查音樂進度條是否正在被使用者拖動
            if !self.musicProgressSlider.isTracking {
                // 若音樂進度條沒有被拖動，執行以下程式碼
//                print("音樂進度條沒有被拖動，進入 updateMusicProgress 方法")   // 測試
                self.updateMusicProgress()
            }
//            else {
//                // 若音樂進度條正在被拖動，執行以下程式碼
//                print("音樂進度條正在被拖動，不執行 updateMusicProgress 方法")  // 測試
//            }
        }
        
        
        // 設置musicProgressSlider的最大、最小值，用與控制音樂的播放進度
        musicProgressSlider.minimumValue = 0
        musicProgressSlider.maximumValue = 1
        musicProgressSlider.value = 0
        // 預設為沒有播放音樂，因此Slider的isEnabled為false
        musicProgressSlider.isEnabled = false
        // 設置slider thumb的圖示
        musicProgressSlider.setThumbImage(UIImage(named: "whiteDot"), for: .normal)
        
        
        // 設置volumeSlider的最大、最小值，用與控制音量
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = 1          // 默認最大音量
        
        // 預設隱藏音樂控制條的View
        volumeView.isHidden = true
        
        // 預設無法點擊上一首、下一首
        fowardButton.isEnabled = false
        backwardButton.isEnabled = false
    }
    

    /// 播放、暫停按鈕
    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        
        // 播放音樂後啟動 musicProgressSlider的控制
        musicProgressSlider.isEnabled = true
        // 啟動上一首、下一首功能
        fowardButton.isEnabled = true
        backwardButton.isEnabled = true

        // 檢查音樂播放器的播放狀態
        switch soundPlayer.timeControlStatus {
        // 目前是暫停狀態
        case .paused:
            // 檢查是否有當前播放的歌曲
            if currentSong != nil {
                // 有一首歌曲正在播放或者已經暫停，所以繼續播放
                soundPlayer.play()
                print("播放器目前暫停，按下播放按鈕")
            } else {
                // 沒有正在播放的歌曲，選擇歌曲清單中的索引歌曲
                print("未有播放歌曲，播放歌曲清單中的歌曲")
                playSong(song: songs[currentSongIndex])
            }
    
            // 更新按鈕的圖片為「pause.circle」，因為播放器已開始播放歌曲，用戶下一步可以選擇暫停
            sender.setImage(UIImage(systemName: "pause.circle"), for: .normal)
            
        // 目前是播放狀態
        case .playing:
            print("播放器目前正在播放，按下暫停按鈕")
            // 播放器正在播放，所以暫停播放
            soundPlayer.pause()
            // 更新按鈕的圖片為「play.circle」，因為播放器已暫停，用戶下一步可以選擇播放
            sender.setImage(UIImage(systemName: "play.circle"), for: .normal)
            
        // 未設置
        default:
            break
        }
    }
    
    
    /// 播放下一首按鈕
    @IBAction func fowardButtonTapped(_ sender: UIButton) {
        if currentSongIndex < songs.count - 1 {
            currentSongIndex += 1
        } else {
            currentSongIndex = 0
        }

        playSong(song: songs[currentSongIndex])
    }
    
    
    /// 播放上一首按鈕
    @IBAction func backwardButtonTapped(_ sender: UIButton) {
        if currentSongIndex > 0 {
            currentSongIndex -= 1
        } else {
            currentSongIndex = songs.count - 1
        }
        
        playSong(song: songs[currentSongIndex])
    }
    
    
    /// 切換歌曲播放模式
    @IBAction func changePlayModeButtonTapped(_ sender: UIButton) {
        // 切換播放模式（播放模式會循環改變）
        switch playMode {
        case .random:
            playMode = .singleRepeat
            sender.setImage(UIImage(systemName: "repeat.1"), for: .normal)
            print("目前是單曲循環模式")
        case .singleRepeat:
            playMode = .sequential
            sender.setImage(UIImage(systemName: "repeat"), for: .normal)
            print("目前是一般播放模式")
        case .sequential:
            playMode = .random
            sender.setImage(UIImage(systemName: "shuffle"), for: .normal)
            print("目前是隨機播放模式")
        }
    }
    
    
    /// 音量大小調整
    @IBAction func volumeSliderValueChanged(_ sender: UISlider) {
        // 設置音量大小為slider的值
        soundPlayer.volume = sender.value
        
        // 根據音量值決定顯示的圖示
        var volumeIconName = ""
        if sender.value == 0.0 {
            volumeIconName = "speaker.slash"
        } else if sender.value <= 0.35 {
            volumeIconName = "speaker.wave.1"
        } else if sender.value <= 0.65 {
            volumeIconName = "speaker.wave.2"
        } else {
            volumeIconName = "speaker.wave.3"
        }
        
        // 更新按鈕的圖片
        volumeButton.setImage(UIImage(systemName: volumeIconName), for: .normal)
    }
    
    
    /// 音量控制顯示按鈕
    @IBAction func volumeButtonTapped(_ sender: UIButton) {
        // 切換 volumeView 的顯示狀態
        volumeView.isHidden = !volumeView.isHidden
    }
    
    
    /// 在滑動進度條時會立即改變播放時間，使用者在滑動進度條時會立即聽到音樂的不同部分。（學習）
    @IBAction func musicProgressSliderValueChanged(_ sender: UISlider) {
        
        // 獲得滑塊的位置
        let sliderValue = sender.value
        
        // 獲得音樂的總時間（單位秒）
        let duration = CMTimeGetSeconds(soundPlayer.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1))

        // 計算新的播放時間
        let newTime = Double(sliderValue) * duration

        // 將新的播放時間設定到播放器
        let seekTime = CMTimeMakeWithSeconds(newTime, preferredTimescale: 1)
        soundPlayer.seek(to: seekTime)
        
        // 計算了新的時間（以秒為單位），並將其轉換為格式化的字符串，用於顯示當前時間和總時間。（當拉動thumb時會即時更新Label）
        let currentLabelValue = String(format: "%02d:%02d", Int(newTime) / 60, Int(newTime) % 60)
        musicCurrentTimeLabel.text = currentLabelValue
        let totalLabelValue = String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60)
        musicTotalTimeLabel.text = totalLabelValue
    }
    
    
    /// 播放一首歌曲
    /// - Parameter song: 參數為歌曲清單中的一首歌曲
    func playSong(song: Song) {
        
        // 將當前歌曲設為選擇播放的歌曲
        currentSong = song
        
        // 更新介面
        backgroundImageView.image = song.coverImage // 背景設置（與專輯封面相同）
        albumNameLabel.text = song.albumName        // 專輯名稱
        songNameLabel.text = song.songName          // 歌曲名稱
        artistLabel.text = song.artist              // 歌手名稱
        coverImageView.image = song.coverImage      // 專輯封面
        
        // 建立一個新的播放項目
        let playerItem = AVPlayerItem(url: song.fileUrl)
        // 將播放項目放入播放器並開始播放
        soundPlayer.replaceCurrentItem(with: playerItem)
        soundPlayer.play()
        
        // 播放音樂的同時確保更新playAndPauseButton的圖片為"pause.circle"，以便顯示當前是播放狀態。
        playAndPauseButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
        
        // 監聽歌曲播放結束的通知
        NotificationCenter.default.addObserver(self, selector: #selector(songDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    /// 當歌曲播放結束時調用（播放模式）
    @objc func songDidEnd() {
        
        // 移除舊的觀察者，否則播放完會產生錯誤（在添加新的Observer之前，需要先移除舊的Observer，以避免多個Observer同時存在導致的問題。）
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        // 根據當前的播放模式來改變歌曲結束時的行為
        switch playMode {
        case .random:
            currentSongIndex = Int.random(in: 0..<songs.count)
//            songs.shuffle()       // 如果採用shuffle，之後切換回一般播放狀態時，歌單會是打亂的狀態，故先用random。
//            currentSongIndex = 0
        case .singleRepeat:
            break
        case .sequential:
            if currentSongIndex < songs.count - 1 {
                currentSongIndex += 1
            } else {
                currentSongIndex = 0        // 測試
            }
        }
        
        playSong(song: songs[currentSongIndex])
        print("當前歌曲播放完畢，自動播放下一首")
    }

    
    // 定期地在音樂播放的過程中讓使用者知道音樂播放的時間（透過 addPeriodicTimeObserver）
    /// 更新音樂時間和進度條
    func updateMusicProgress() {
        
//        print("updateMusicProgress 方法被執行")  // 測試
        
        // 確保音樂播放器有正確的 currentItem
        if let currentTime = soundPlayer.currentItem?.currentTime(),
           let duration = soundPlayer.currentItem?.duration {

            // 只在成功解包 currentTime 和 duration 時，執行進行播放時間和總時間的處理
            let currentTimeInSeconds = CMTimeGetSeconds(currentTime)
            let durationInSeconds = CMTimeGetSeconds(duration)
            
            // 計算當前播放進度的比例，用於更新音樂進度條的顯示
            let progress = Float(currentTimeInSeconds / durationInSeconds)
            musicProgressSlider.value = progress
            
            // 將當前時間和總時間轉換為格式化的字串，用於顯示在音樂播放介面上（用於播放時一直追蹤音樂進度顯示）
            musicCurrentTimeLabel.text = formatSecondsToString(seconds: currentTimeInSeconds)
            musicTotalTimeLabel.text = formatSecondsToString(seconds: durationInSeconds)
        } else {
            
            // 如果 currentTime 或 duration 解包失敗，可以在這裡提前退出當前的執行範圍
            return
        }
    }


    /// 格式化秒數為時間字串（學習）
    /// - Parameter seconds: 需要被格式化的秒數，數值為Double
    /// - Returns: 回傳格式化後的時間字串，格式為 "分鐘：秒鐘"
    func formatSecondsToString(seconds: Double) -> String {
        
        // 如果傳入的秒數是 NaN（Not a Number） 則直接回傳 "00:00"
        if seconds.isNaN {
            return "00:00"
        }
        
        // 將傳入的秒數除以 60 得到分鐘數，並轉為整數
        let mins = Int(seconds / 60)
        
        // 使用 truncatingRemainder(dividingBy:) 函式獲得傳入的秒數除以 60 的餘數，這就是剩餘的秒數，然後轉為整數
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        // String(format:) 來生成格式化的時間字串。"%02d:%02d" 表示兩個兩位數的整數，如果不足兩位則前面補零
        let str = String(format: "%02d:%02d", mins, secs)
        
        // 回傳格式化後的時間字串
        return str
    }
    
}



// 滑塊抖動版本
//import UIKit
//import AVFoundation
//
//// 定義音樂播放的 UIViewController
//class MusicPlayerViewController: UIViewController {
//
//    /// 背景
//    @IBOutlet weak var backgroundImageView: UIImageView!
//    /// 專輯名稱
//    @IBOutlet weak var albumNameLabel: UILabel!
//    /// 專輯封面
//    @IBOutlet weak var coverImageView: UIImageView!
//    /// 歌曲名稱
//    @IBOutlet weak var songNameLabel: UILabel!
//    /// 歌手名稱
//    @IBOutlet weak var artistLabel: UILabel!
//    /// 音樂進度條（用於追蹤當前音樂播放的時間進度以及可以滑動調整播放時間）
//    @IBOutlet weak var musicProgressSlider: UISlider!
//    /// 播放以及暫停按鈕的Outlet
//    @IBOutlet weak var playAndPauseButton: UIButton!
//    /// 顯示該首音樂正在進行的時間
//    @IBOutlet weak var musicCurrentTimeLabel: UILabel!
//    /// 顯示該首音樂的完整時間
//    @IBOutlet weak var musicTotalTimeLabel: UILabel!
//    /// 音量調整
//    @IBOutlet weak var volumeSlider: UISlider!
//    /// 顯示音量控制條的View
//    @IBOutlet weak var volumeView: UIView!
//    /// 音量按鈕顯示（隨著音量大小聲而變化圖示）
//    @IBOutlet weak var volumeButton: UIButton!
//
//    /// 初始化音樂播放器
//    let soundPlayer = AVPlayer()
//
//    /// 追蹤目前正在播放的歌曲
//    var currentSong: Song?
//
//    /// 跟蹤當前播放的歌曲索引
//    var currentSongIndex = 0
//
//    /// 記錄當前的播放模式，設置為初始模式
//    var playMode: PlayMode = .sequential
//
//    /// 建立歌曲清單
//    var songs: [Song] = [
//        Song(albumName: "歹勢好勢", songName: "踅夜市", artist: "拍謝少年", coverImage: UIImage(named: "歹勢好勢"), fileUrl: Bundle.main.url(forResource: "踅夜市", withExtension: "mp3")!),
//        Song(albumName: "愛情的盡頭", songName: "Last Dance", artist: "伍佰", coverImage: UIImage(named: "愛情的盡頭"), fileUrl: Bundle.main.url(forResource: "Last dance", withExtension: "mp3")!),
//        Song(albumName: "醜奴兒", songName: "大風吹", artist: "草東沒有派對", coverImage: UIImage(named: "醜奴兒"), fileUrl: Bundle.main.url(forResource: "大風吹", withExtension: "mp3")!),
//        Song(albumName: "台北嘻哈故事", songName: "台北嘻哈故事之一", artist: "蛋堡", coverImage: UIImage(named: "台北嘻哈故事"), fileUrl: Bundle.main.url(forResource: "台北嘻哈故事 之一", withExtension: "mp3")!),
//        Song(albumName: "GDN EXPRESS", songName: "Yesterday", artist: "國蛋 GorDoN", coverImage: UIImage(named: "GDN EXPRESS"), fileUrl: Bundle.main.url(forResource: "Yesterday", withExtension: "mp3")!),
//        Song(albumName: "Ride On Time", songName: "RIDE ON TIME", artist: "山下 達郎", coverImage: UIImage(named: "Ride On Time Cover"), fileUrl: Bundle.main.url(forResource: "RIDE ON TIME", withExtension: "mp3")!),
//        Song(albumName: "Midnight Pretenders", songName: "Midnight Pretenders", artist: "亜蘭 知子", coverImage: UIImage(named: "Midnight Pretenders Cover"), fileUrl: Bundle.main.url(forResource: "Midnight Pretenders", withExtension: "mp3")!)
//    ]
//
//    // 當 view 加載完成後執行
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // 每秒呼叫一次 updateMusicProgress() 方法。（addPeriodicTimeObserver運用）（學習）
//        soundPlayer.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .main) { time in
//            self.updateMusicProgress()
//        }
//
//        // 設置musicProgressSlider的最大、最小值，用與控制音樂的播放進度
//        musicProgressSlider.minimumValue = 0
//        musicProgressSlider.maximumValue = 1
//        musicProgressSlider.value = 0
//        // 預設為沒有播放音樂，因此Slider的isEnabled為false
//        musicProgressSlider.isEnabled = false
//        // 設置slider thumb的圖示
//        musicProgressSlider.setThumbImage(UIImage(named: "whiteDot"), for: .normal)
//
//
//        // 設置volumeSlider的最大、最小值，用與控制音量
//        volumeSlider.minimumValue = 0
//        volumeSlider.maximumValue = 1
//        volumeSlider.value = 1          // 默認最大音量
//
//        // 預設隱藏音樂控制條的View
//        volumeView.isHidden = true
//    }
//
//
//    /// 播放、暫停按鈕
//    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
//
//        // 播放音樂後啟動 musicProgressSlider的控制
//        musicProgressSlider.isEnabled = true
//
//        // 檢查音樂播放器的播放狀態
//        switch soundPlayer.timeControlStatus {
//        // 目前是暫停狀態
//        case .paused:
//            // 檢查是否有當前播放的歌曲
//            if currentSong != nil {
//                // 有一首歌曲正在播放或者已經暫停，所以繼續播放
//                soundPlayer.play()
//                print("播放器目前暫停，準備開始播放")
//            } else {
//                // 沒有正在播放的歌曲，選擇歌曲清單中的索引歌曲
//                print("未有播放歌曲，播放歌曲清單中的歌曲")
//                playSong(song: songs[currentSongIndex])
//            }
//
//            // 更新按鈕的圖片為「pause.circle」，因為播放器要開始播放歌曲
//            sender.setImage(UIImage(systemName: "pause.circle"), for: .normal)
//
//        // 目前是播放狀態
//        case .playing:
//            print("播放器目前正在播放，準備暫停")
//            // 播放器正在播放，所以暫停播放
//            soundPlayer.pause()
//            // 更新按鈕的圖片為「play.circl」
//            sender.setImage(UIImage(systemName: "play.circle"), for: .normal)
//
//        // 未設置
//        default:
//            break
//        }
//    }
//
//
//    /// 播放下一首按鈕
//    @IBAction func fowardButtonTapped(_ sender: UIButton) {
//        if currentSongIndex < songs.count - 1 {
//            currentSongIndex += 1
//        } else {
//            currentSongIndex = 0
//        }
//
//        playSong(song: songs[currentSongIndex])
//    }
//
//
//    /// 播放上一首按鈕
//    @IBAction func backwardButtonTapped(_ sender: UIButton) {
//        if currentSongIndex > 0 {
//            currentSongIndex -= 1
//        } else {
//            currentSongIndex = songs.count - 1
//        }
//
//        playSong(song: songs[currentSongIndex])
//    }
//
//
//    /// 切換歌曲播放模式
//    @IBAction func changePlayModeButtonTapped(_ sender: UIButton) {
//        // 切換播放模式（播放模式會循環改變）
//        switch playMode {
//        case .random:
//            playMode = .singleRepeat
//            sender.setImage(UIImage(systemName: "repeat.1"), for: .normal)
//            print("目前是單曲循環模式")
//        case .singleRepeat:
//            playMode = .sequential
//            sender.setImage(UIImage(systemName: "repeat"), for: .normal)
//            print("目前是一般播放模式")
//        case .sequential:
//            playMode = .random
//            sender.setImage(UIImage(systemName: "shuffle"), for: .normal)
//            print("目前是隨機播放模式")
//        }
//    }
//
//
//    /// 音量大小調整
//    @IBAction func volumeSliderValueChanged(_ sender: UISlider) {
//        // 設置音量大小為slider的值
//        soundPlayer.volume = sender.value
//
//        // 根據音量值決定顯示的圖示
//        var volumeIconName = ""
//        if sender.value == 0.0 {
//            volumeIconName = "speaker.slash"
//        } else if sender.value <= 0.35 {
//            volumeIconName = "speaker.wave.1"
//        } else if sender.value <= 0.65 {
//            volumeIconName = "speaker.wave.2"
//        } else {
//            volumeIconName = "speaker.wave.3"
//        }
//
//        // 更新按鈕的圖片
//        volumeButton.setImage(UIImage(systemName: volumeIconName), for: .normal)
//    }
//
//
//    /// 音量控制顯示按鈕
//    @IBAction func volumeButtonTapped(_ sender: UIButton) {
//        // 切換 volumeView 的顯示狀態
//        volumeView.isHidden = !volumeView.isHidden
//    }
//
//
//    /// 在滑動進度條時會立即改變播放時間，使用者在滑動進度條時會立即聽到音樂的不同部分。（學習）
//    @IBAction func musicProgressSliderValueChanged(_ sender: UISlider) {
//
//        // 獲得滑塊的位置
//        let sliderValue = sender.value
//
//        // 獲得音樂的總時間（單位秒）
//        let duration = CMTimeGetSeconds(soundPlayer.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1))
//
//        // 計算新的播放時間
//        let newTime = Double(sliderValue) * duration
//
//        // 將新的播放時間設定到播放器
//        let seekTime = CMTimeMakeWithSeconds(newTime, preferredTimescale: Int32(NSEC_PER_SEC))
//        soundPlayer.seek(to: seekTime)
//    }
//
//
//    /// 播放一首歌曲
//    /// - Parameter song: 參數為歌曲清單中的一首歌曲
//    func playSong(song: Song) {
//
//        // 將當前歌曲設為選擇播放的歌曲
//        currentSong = song
//
//        // 更新介面
//        backgroundImageView.image = song.coverImage // 背景設置（與專輯封面相同）
//        albumNameLabel.text = song.albumName        // 專輯名稱
//        songNameLabel.text = song.songName          // 歌曲名稱
//        artistLabel.text = song.artist              // 歌手名稱
//        coverImageView.image = song.coverImage      // 專輯封面
//
//        // 建立一個新的播放項目
//        let playerItem = AVPlayerItem(url: song.fileUrl)
//
//        // 將播放項目放入播放器並開始播放
//        soundPlayer.replaceCurrentItem(with: playerItem)
//        soundPlayer.play()
//
//        // 播放音樂的同時確保更新playAndPauseButton的圖片為"pause.circle"，以便顯示當前是播放狀態。
//        playAndPauseButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
//
//        // 監聽歌曲播放結束的通知
//        NotificationCenter.default.addObserver(self, selector: #selector(songDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
//    }
//
//    /// 當歌曲播放結束時調用（播放模式）
//    @objc func songDidEnd() {
//
//        // 移除舊的觀察者，否則播放完會產生錯誤（在添加新的Observer之前，需要先移除舊的Observer，以避免多個Observer同時存在導致的問題。）
//        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
//
//        // 根據當前的播放模式來改變歌曲結束時的行為
//        switch playMode {
//        case .random:
//            currentSongIndex = Int.random(in: 0..<songs.count)
////            songs.shuffle()       // 如果採用shuffle，之後切換回一般播放狀態時，歌單會是打亂的狀態，故先用random。
////            currentSongIndex = 0
//        case .singleRepeat:
//            break
//        case .sequential:
//            if currentSongIndex < songs.count - 1 {
//                currentSongIndex += 1
//            } else {
//                currentSongIndex = 0        // 測試
//            }
//        }
//
//        playSong(song: songs[currentSongIndex])
//        print("當前歌曲播放完畢，自動播放下一首")
//    }
//
//
//    // 定期地在音樂播放的過程中讓使用者知道音樂播放的時間（透過 addPeriodicTimeObserver）
//    /// 更新音樂時間和進度條
//    func updateMusicProgress() {
//
//        // 獲得目前播放的時間（單位秒）
//        let currentTime = CMTimeGetSeconds(soundPlayer.currentTime())
//
//        // 獲得音樂的總時間（單位秒）
//        let duration = CMTimeGetSeconds(soundPlayer.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1))
//
//        // 更新進度條的值
//        musicProgressSlider.value = Float(currentTime / duration)
//
//        // 更新音樂的目前時間和總時間（呼叫formatSecondsToString格式化秒數為時間字串）
//        musicCurrentTimeLabel.text = formatSecondsToString(seconds: currentTime)
//        musicTotalTimeLabel.text = formatSecondsToString(seconds: duration)
//    }
//
//
//    /// 格式化秒數為時間字串（學習）
//    /// - Parameter seconds: 需要被格式化的秒數，數值為Double
//    /// - Returns: 回傳格式化後的時間字串，格式為 "分鐘：秒鐘"
//    func formatSecondsToString(seconds: Double) -> String {
//
//        // 如果傳入的秒數是 NaN（Not a Number） 則直接回傳 "00:00"
//        if seconds.isNaN {
//            return "00:00"
//        }
//
//        // 將傳入的秒數除以 60 得到分鐘數，並轉為整數
//        let mins = Int(seconds / 60)
//
//        // 使用 truncatingRemainder(dividingBy:) 函式獲得傳入的秒數除以 60 的餘數，這就是剩餘的秒數，然後轉為整數
//        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
//
//        // String(format:) 來生成格式化的時間字串。"%02d:%02d" 表示兩個兩位數的整數，如果不足兩位則前面補零
//        let str = String(format: "%02d:%02d", mins, secs)
//
//        // 回傳格式化後的時間字串
//        return str
//    }
//
//}








/// 初始版本
//import UIKit
//import AVFoundation
//
//// 定義音樂播放的 UIViewController
//class MusicPlayerViewController: UIViewController {
//
//    /// 背景
//    @IBOutlet weak var backgroundImageView: UIImageView!
//    /// 專輯名稱
//    @IBOutlet weak var albumNameLabel: UILabel!
//    /// 專輯封面
//    @IBOutlet weak var coverImageVIew: UIImageView!
//    /// 歌曲名稱
//    @IBOutlet weak var songNameLabel: UILabel!
//    /// 歌手名稱
//    @IBOutlet weak var artistLabel: UILabel!
//    /// 音樂進度條（用於追蹤當前音樂播放的時間進度以及可以滑動調整播放時間
//    @IBOutlet weak var musicProgressSlider: UISlider!
//
//    /// 播放以及暫停按鈕的Outlet
//    @IBOutlet weak var playAndPauseButton: UIButton!
//
//    /// 初始化音樂播放器
//    let soundPlayer = AVPlayer()
//
//    /// 追蹤目前正在播放的歌曲
//    var currentSong: Song?
//
//    /// 建立歌曲清單
//    var songs: [Song] = [
//        Song(albumName: "歹勢好勢", songName: "踅夜市", artist: "拍謝少年", coverImage: UIImage(named: "歹勢好勢"), fileUrl: Bundle.main.url(forResource: "踅夜市", withExtension: "mp3")!),
//        Song(albumName: "愛情的盡頭", songName: "Last Dance", artist: "伍佰", coverImage: UIImage(named: "愛情的盡頭"), fileUrl: Bundle.main.url(forResource: "Last dance", withExtension: "mp3")!),
//        Song(albumName: "醜奴兒", songName: "大風吹", artist: "草東沒有派對", coverImage: UIImage(named: "醜奴兒"), fileUrl: Bundle.main.url(forResource: "大風吹", withExtension: "mp3")!),
//        Song(albumName: "台北嘻哈故事", songName: "台北嘻哈故事之一", artist: "蛋堡", coverImage: UIImage(named: "台北嘻哈故事"), fileUrl: Bundle.main.url(forResource: "台北嘻哈故事 之一", withExtension: "mp3")!),
//        Song(albumName: "GDN EXPRESS", songName: "Yesterday", artist: "國蛋 GorDoN", coverImage: UIImage(named: "GDN EXPRESS"), fileUrl: Bundle.main.url(forResource: "Yesterday", withExtension: "mp3")!),
//        Song(albumName: "Ride On Time", songName: "RIDE ON TIME", artist: "山下 達郎", coverImage: UIImage(named: "Ride On Time Cover"), fileUrl: Bundle.main.url(forResource: "RIDE ON TIME", withExtension: "mp3")!),
//        Song(albumName: "Midnight Pretenders", songName: "Midnight Pretenders", artist: "亜蘭 知子", coverImage: UIImage(named: "Midnight Pretenders Cover"), fileUrl: Bundle.main.url(forResource: "Midnight Pretenders", withExtension: "mp3")!)
//    ]
//
//
//    /// 跟蹤當前播放的歌曲索引
//    var currentSongIndex = 0
//
//
//    // 當視圖加載完成後執行
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
////        playSong(song: songs[6])    // 測試
//    }
//
//
//    /// 播放、暫停按鈕
//    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
//
//        // 檢查音樂播放器的播放狀態
//        switch soundPlayer.timeControlStatus {
//        // 目前是暫停狀態
//        case .paused:
//            // 檢查是否有當前播放的歌曲
//            if let currentSong = currentSong {
//                // 有一首歌曲正在播放或者已經暫停，所以繼續播放
//                soundPlayer.play()
//                print("播放器目前暫停，準備開始播放")
//            } else {
//                // 沒有正在播放的歌曲，隨機選擇一首歌曲來播放
//                print("未有播放歌曲，隨機選擇進行播放")
//                playSong(song: songs.randomElement()!)
//            }
//
//            // 更新按鈕的圖片為「暫停」，因為播放器要開始播放歌曲
//            sender.setImage(UIImage(systemName: "pause.circle"), for: .normal)
//
//        // 目前是播放狀態
//        case .playing:
//            print("播放器目前正在播放，準備暫停")
//            // 播放器正在播放，所以暫停播放
//            soundPlayer.pause()
//
//            // 更新按鈕的圖片為「播放」
//            sender.setImage(UIImage(systemName: "play.circle"), for: .normal)
//
//        // 未設置
//        default:
//            break
//        }
//    }
//
//    /// 播放下一首按鈕
//    @IBAction func fowardButtonTapped(_ sender: UIButton) {
//        if currentSongIndex < songs.count - 1 {
//            currentSongIndex += 1
//        } else {
//            currentSongIndex = 0
//        }
//
//        playSong(song: songs[currentSongIndex])
//    }
//
//
//    /// 播放上一首按鈕
//    @IBAction func backwardButtonTapped(_ sender: UIButton) {
//        if currentSongIndex > 0 {
//            currentSongIndex -= 1
//        } else {
//            currentSongIndex = songs.count - 1
//        }
//
//        playSong(song: songs[currentSongIndex])
//    }
//
//    /// 播放一首歌曲
//    /// - Parameter song: 參數為歌曲清單中的一首歌曲
//    func playSong(song: Song) {
//
//        // 將當前歌曲設為選擇播放的歌曲
//        currentSong = song
//
//        // 更新介面
//        backgroundImageView.image = song.coverImage // 背景設置（與專輯封面相同）
//        albumNameLabel.text = song.albumName        // 專輯名稱
//        songNameLabel.text = song.songName          // 歌曲名稱
//        artistLabel.text = song.artist              // 歌手名稱
//        coverImageVIew.image = song.coverImage      // 專輯封面
//
//        // 建立一個新的播放項目
//        let playerItem = AVPlayerItem(url: song.fileUrl)
//
//        // 將播放項目放入播放器並開始播放
//        soundPlayer.replaceCurrentItem(with: playerItem)
//        soundPlayer.play()
//
//        // 播放音樂的同時確保更新playAndPauseButton的圖片為"pause.circle"，以便顯示當前是播放狀態。
//        playAndPauseButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
//
//        // 監聽歌曲播放結束的通知
//        NotificationCenter.default.addObserver(self, selector: #selector(songDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
//    }
//
//
//    /// 當歌曲播放結束時調用
//    @objc func songDidEnd() {
//
//        // 移除舊的觀察者（在添加新的Observer之前，需要先移除舊的Observer，以避免多個Observer同時存在導致的問題。）
//        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
//
//        // 播放下一首歌曲
//        if currentSongIndex < songs.count {
//            currentSongIndex += 1
//        } else {
//            currentSongIndex = 0        // 測試
//        }
//
//        playSong(song: songs[currentSongIndex])
//        print("當前歌曲播放完畢，自動播放下一首")
//    }
//}
