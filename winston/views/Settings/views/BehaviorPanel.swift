//
//  Behavior.swift
//  winston
//
//  Created by Igor Marcossi on 05/07/23.
//

import SwiftUI
import Defaults

struct BehaviorPanel: View {
  @Default(.maxPostLinkImageHeightPercentage) var maxPostLinkImageHeightPercentage
  @Default(.openYoutubeApp) var openYoutubeApp
  @Default(.preferredSort) var preferredSort
  @Default(.preferredCommentSort) var preferredCommentSort
  @Default(.blurPostLinkNSFW) var blurPostLinkNSFW
  @Default(.blurPostNSFW) var blurPostNSFW
  
  var body: some View {
    List {
      Section("General") {
        Toggle("Open Youtube videos externally", isOn: $openYoutubeApp)
        
        VStack(alignment: .leading) {
          HStack {
            Text("Max posts image height")
            Spacer()
            Text(maxPostLinkImageHeightPercentage == 110 ? "Original" : "\(Int(maxPostLinkImageHeightPercentage))%")
              .opacity(0.6)
          }
          Slider(value: $maxPostLinkImageHeightPercentage, in: 10...110, step: 10)
        }
      }

        Section("Posts list") {
          Picker("Sorting", selection: $preferredSort) {
            ForEach(SubListingSortOption.allCases, id: \.self) { val in
              Label(val.rawVal.id.capitalized, systemImage: val.rawVal.icon)
            }
          }
          Toggle("Blur NSFW content", isOn: $blurPostLinkNSFW)
        }

        Section("Opened posts") {
            Picker("Comments sorting", selection: $preferredCommentSort) {
              ForEach(CommentSortOption.allCases, id: \.self) { val in
                Label(val.rawVal.id.capitalized, systemImage: val.rawVal.icon)
              }
            }
          Toggle("Blur NSFW content", isOn: $blurPostNSFW)
        }
    }
    .navigationTitle("Behavior")
    .navigationBarTitleDisplayMode(.inline)
  }
}
//
//struct Behavior_Previews: PreviewProvider {
//    static var previews: some View {
//        Behavior()
//    }
//}
