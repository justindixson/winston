//
//  SubredditIcon.swift
//  winston
//
//  Created by Igor Marcossi on 13/07/23.
//

import Foundation
import SwiftUI
import Kingfisher

struct SubredditIcon: View {
  var data: SubredditData
  var size: CGFloat = 30
  var body: some View {
    let communityIcon = data.community_icon.split(separator: "?")
    if let icon = data.icon_img == "" || data.icon_img == nil ? communityIcon.count > 0 ? String(communityIcon[0]) : "" : data.icon_img, icon != "" {
      KFImage(URL(string: icon)!)
        .resizable()
        .fade(duration: 0.5)
        .scaledToFill()
        .frame(width: size, height: size)
        .mask(Circle())
    } else {
      Text(String((data.display_name ?? data.id).prefix(1)).uppercased())
        .frame(width: size, height: size)
        .background(Color.hex(String((firstNonEmptyString(data.key_color, data.primary_color, "#828282") ?? "").dropFirst(1))), in: Circle())
        .mask(Circle())
        .fontSize(CGFloat(Int(size * 0.535)), .semibold)
    }
  }
}

func firstNonEmptyString(_ strings: String?...) -> String? {
    for string in strings {
        if let string = string, !string.isEmpty {
            return string
        }
    }
    return nil
}
