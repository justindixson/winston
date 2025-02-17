//
//  SubItem.swift
//  winston
//
//  Created by Igor Marcossi on 05/08/23.
//

import SwiftUI

struct SubItem: View {
  @EnvironmentObject private var router: Router
  @Environment(\.editMode) var editMode
  @ObservedObject var sub: Subreddit
  var body: some View {
    if let data = sub.data {
      let favorite = data.user_has_favorited ?? false
      Button {
        router.path.append(SubViewType.posts(sub))
      } label: {
        HStack {
          SubredditIcon(data: data)
          Text(data.display_name ?? "")
          
          Spacer()
          
          Image(systemName: "star.fill")
            .foregroundColor(favorite ? .blue : .gray.opacity(0.3))
            .highPriorityGesture( TapGesture().onEnded { Task { await sub.favoriteToggle() } } )
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.automatic)
      
    } else {
      Text("Error")
    }
  }
}
