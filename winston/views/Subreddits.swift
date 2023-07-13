//
//  Posts.swift
//  winston
//
//  Created by Igor Marcossi on 24/06/23.
//

import SwiftUI
import Defaults
import Kingfisher

let alphabetLetters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }

struct SubItem: View {
  var reset: Bool
  var sub: Subreddit
  @State var active = false
  var body: some View {
    if let data = sub.data {
      HStack {
        ZStack {
          SubredditIcon(data: data)
        }
        Text(data.display_name ?? "")
      }
      .onChange(of: reset) { _ in active = false }
      .background(
        NavigationLink(destination: SubredditPosts(subreddit: sub), isActive: $active, label: { EmptyView() }).buttonStyle(EmptyButtonStyle()).opacity(0).allowsHitTesting(false)
      )
    } else {
      Text("Error")
    }
  }
}

class SubsDictContainer: ObservableObject {
  @Published var data: [String: [Subreddit]]?
}

struct Subreddits: View {
  var reset: Bool
  @Environment(\.openURL) var openURL
  @EnvironmentObject var redditAPI: RedditAPI
  @Default(.subreddits) var subreddits
  @State var searchText: String = ""
  @StateObject var subsDict = SubsDictContainer()
  
  func sort(_ subs: [ListingChild<SubredditData>]) -> [String: [Subreddit]] {
    return Dictionary(grouping: subs.compactMap { $0.data }, by: { String($0.display_name?.prefix(1) ?? "").uppercased() })
      .mapValues { items in items.sorted { ($0.display_name ?? "") < ($1.display_name ?? "") }.map { Subreddit(data: $0, api: redditAPI) } }
  }
  
  var body: some View {
    GoodNavigator {
      List {
        if let subsDictData = subsDict.data {
          if searchText != "" {
                        ForEach(Array(Array(subsDictData.values).flatMap { $0 }.filter { ($0.data?.display_name ?? "").lowercased().contains(searchText.lowercased()) }).sorted { ($0.data?.display_name?.lowercased() ?? "") < ($1.data?.display_name?.lowercased() ?? "") }, id: \.self.id) { sub in
                          SubItem(reset: reset, sub: sub)
                        }
          } else {
            Section("FAVORITES") {
                            ForEach(Array(subsDictData.values).flatMap { $0 }.filter { $0.data?.user_has_favorited ?? false }.sorted { ($0.data?.display_name?.lowercased() ?? "") < ($1.data?.display_name?.lowercased() ?? "") }, id: \.self.id) { sub in
                              SubItem(reset: reset, sub: sub)
                            }
                          }
                          ForEach(Array(subsDictData.keys).sorted { $0 < $1 }, id: \.self) { letter in
                            if let subs = subsDictData[letter] {
                              Section(header: Text(letter)) {
                                ForEach(subs) { sub in
                                  SubItem(reset: reset, sub: sub)
                                }
                              }
                            }
            }
          }
        }
      }
      .searchable(text: $searchText, prompt: "Search my subreddits")
      .refreshable {
        await redditAPI.fetchSubs()
      }
      .onAppear {
        if subsDict.data  == nil {
          if subreddits.count > 0 {
            subsDict.data = sort(subreddits)
          }
          
          Task {
            await redditAPI.fetchSubs()
          }
        }
      }
      .onChange(of: subreddits) { _ in
        withAnimation(nil) {
          subsDict.data = sort(subreddits)
        }
      }
      .navigationTitle("Subs")
      //        .onDelete(perform: deleteItems)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          EditButton()
        }
        ToolbarItem {
          Button(action: {}) {
            Label("Add Item", systemImage: "plus")
          }
        }
      }
    }
  }
}

//struct Posts_Previews: PreviewProvider {
//  static var previews: some View {
//    Posts()
//  }
//}
