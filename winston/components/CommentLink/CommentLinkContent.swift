//
//  CommentLinkContent.swift
//  winston
//
//  Created by Igor Marcossi on 08/07/23.
//

import SwiftUI
import Defaults

struct CommentLinkContent: View {
  @Default(.preferenceShowCommentsAvatars) var preferenceShowCommentsAvatars
  var lineLimit: Int?
  @ObservedObject var comment: Comment
  var avatarsURL: [String:String]?
  var showReplies = true
  @Binding var collapsed: Bool
  @State var prepareCollapsed = false
  @State var showReplyModal = false
  @State var pressing = false
  @State var collapsableHeight: CGFloat = 0
  @State var disableCollapse = true
  @State var hideText = false
  @State var collapseTimer: TimerCancellable?
  @State var hideTextTimer: TimerCancellable?
  var body: some View {
    if let data = comment.data {
      
      VStack(alignment: .leading, spacing: 8) {
        
        HStack {
          if let author = data.author, let created = data.created  {
            Badge(showAvatar: preferenceShowCommentsAvatars, author: author, fullname: data.author_fullname, created: created, avatarURL: avatarsURL?[data.author_fullname!])
          }
          
          Spacer()
          
          if let ups = data.ups, let downs = data.downs {
            HStack(alignment: .center, spacing: 4) {
              Image(systemName: "arrow.up")
                .foregroundColor(data.likes != nil && data.likes! ? .orange : .gray)
              
              let downup = Int(ups - downs)
              Text(formatBigNumber(downup))
                .foregroundColor(downup == 0 ? .gray : downup > 0 ? .orange : .blue)
                .fontSize(14, .semibold)
              
              Image(systemName: "arrow.down")
                .foregroundColor(data.likes != nil && !data.likes! ? .blue : .gray)
            }
            .fontSize(14, .medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule(style: .continuous).fill(.secondary.opacity(0.1)))
            .allowsHitTesting(false)
            
            if collapsed {
              Image(systemName: "eye.slash.fill")
                .fontSize(14, .medium)
                .opacity(0.5)
                .allowsHitTesting(false)
            }
            
          }
        }
        if let body = data.body {
          //              GeometryReader { geo in
          Text(body.md())
          //                Text("\(data.depth ?? 99)")
            .fontSize(15)
            .lineLimit(lineLimit)
            .animation(nil, value: collapsed)
          //                  .clipped()
            .opacity(hideText ? 0 : 1)
            .fixedSize(horizontal: false, vertical: true)
            .allowsHitTesting(false)
          //                  .frame(maxHeight: collapsed ? 0 : nil, alignment: .topLeading)
        }
      }
      //          .buttonStyle(ShrinkableBtnStyle())
      .contentShape(Rectangle())
      .background(
        RR(20, .secondary.opacity(pressing ? 0.1 : 0))
          .padding(.vertical, -14)
          .padding(.horizontal, -16)
          .allowsHitTesting(false)
      )
      .swipyActions(
        pressing: $pressing,
        onTap: {
          //             withAnimation(spring) {
          //              collapsed.toggle()
          //             }
          if collapsed {
            if hideTextTimer != nil {
              hideTextTimer?.cancel()
            }
            withAnimation(spring) {
              hideTextTimer = nil
              hideText = false
              collapseTimer = cancelableTimer(0.4, action: {
                withAnimation(spring) {
                  collapsed = false
                  disableCollapse = true
                  collapseTimer = nil
                }
              })
            }
          } else {
            if collapseTimer != nil {
              collapseTimer?.cancel()
              withAnimation(spring) {
                collapseTimer = nil
                collapsed = true
              }
            } else {
              doThisAfter(0) {
                prepareCollapsed = true
              }
            }
          }
        },
        leftActionHandler: {
          Task {
            _ = await comment.vote(action: .down)
          }
        }, rightActionHandler: {
          Task {
            _ = await comment.vote(action: .up)
          }
        }, secondActionHandler: {
          showReplyModal = true
        })
      .sheet(isPresented: $showReplyModal) {
        ReplyModalComment(comment: comment)
      }
      .compositingGroup()
      //        .padding(.vertical, (data.depth == 0 || !showReplies) && preferenceShowCommentsCards ? 0 : 6)
      .padding(.vertical, 8)
      //        .padding(.bottom, data.depth != 0 || !showReplies ? 12 : 0)
      .fixedSize(horizontal: false, vertical: true)
      .background(
        !prepareCollapsed
        ? nil
        : GeometryReader { geo in
          Color.clear
            .onAppear {
              if prepareCollapsed {
                if hideTextTimer != nil {
                  hideTextTimer?.cancel()
                  hideTextTimer = nil
                }
                collapsableHeight = geo.size.height
                prepareCollapsed = false
                doThisAfter(0) {
                  disableCollapse = false
                  doThisAfter(0) {
                    withAnimation(spring) {
                      collapsed = true
                      hideTextTimer = cancelableTimer(0.3, action: {
                        withAnimation(spring) {
                          hideText = true
                        }
                        hideTextTimer = nil
                      })
                    }
                  }
                }
              }
              
            }
        }
      )
      .modifier(AnimatingCellHeight(height: collapsableHeight == 0 ? 0 : hideText ? 47 : collapsableHeight, disable: disableCollapse))
      //        .background(collapsed ? .red : .clear)
      .opacity(collapsed ? 0.5 : 1)
      //      .id("\(comment.id)-content")
    } else {
      Text("oops")
    }
  }
}

//struct CommentLinkContent_Previews: PreviewProvider {
//    static var previews: some View {
//        CommentLinkContent()
//    }
//}

struct AnimatingCellHeight: AnimatableModifier {
  var height: CGFloat = 0
  var disable: Bool
  
  var animatableData: CGFloat {
    get { height }
    set { height = newValue }
  }
  
  func body(content: Content) -> some View {
    content.frame(maxHeight: disable ? nil : height, alignment: .topLeading)
  }
}
