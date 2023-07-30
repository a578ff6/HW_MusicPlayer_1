//
//  Song.swift
//  HW_MusicPlayer_1
//
//  Created by 曹家瑋 on 2023/7/25.
//

import Foundation
import UIKit

/// 音樂資訊（專輯名稱、歌曲名稱、歌手、封面、檔案來源）
struct Song {
    var albumName: String
    var songName: String
    var artist: String
    var coverImage: UIImage?
    var fileUrl: URL
}
