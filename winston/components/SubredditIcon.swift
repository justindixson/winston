//
//  SubredditIcon.swift
//  winston
//
//  Created by Igor Marcossi on 13/07/23.
//

import Foundation
import SwiftUI
import LonginusSwiftUI

struct SubredditBaseIcon: View {
  var name: String
  var iconURLStr: String?
  var id: String
  var size: CGFloat = 30
  var color: String?
  var body: some View {
    if let icon = iconURLStr, !icon.isEmpty, let iconURL = URL(string: icon) {
      LGImage(source: iconURL, placeholder: {
        ProgressView()
      }, options: [.imageWithFadeAnimation])
        .resizable()
        .scaledToFill()
        .frame(width: size, height: size)
        .mask(Circle())
    } else {
      Text(String((name).prefix(1)).uppercased())
        .frame(width: size, height: size)
        .background(Color.hex(String((firstNonEmptyString(color, "#828282") ?? "").dropFirst(1))), in: Circle())
        .mask(Circle())
        .fontSize(CGFloat(Int(size * 0.535)), .semibold)
        .foregroundColor(.primary)
    }
  }
}

struct SubredditIcon: View {
  var data: SubredditData
  var size: CGFloat = 30
  var body: some View {
    let communityIcon = data.community_icon.split(separator: "?")
    var icon = data.icon_img == "" || data.icon_img == nil ? communityIcon.count > 0 ? String(communityIcon[0]) : "" : data.icon_img
    SubredditBaseIcon(name: data.display_name ?? data.id, iconURLStr: icon == "" ? nil : icon, id: data.id, size: size, color: firstNonEmptyString(data.key_color, data.primary_color, "#828282") ?? "")
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
