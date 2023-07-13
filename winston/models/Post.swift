//
//  PostData.swift
//  winston
//
//  Created by Igor Marcossi on 26/06/23.
//

import Foundation
import Defaults

typealias Post = GenericRedditEntity<PostData>

extension Post {
  convenience init(data: T, api: RedditAPI) {
    self.init(data: data, api: api, typePrefix: "t3_")
  }
  
  convenience init(id: String, api: RedditAPI) {
    self.init(id: id, api: api, typePrefix: "t3_")
  }
  
  func reply(_ text: String) async -> Bool {
    if let fullname = data?.name {
      let result = await redditAPI.newReply(text, fullname) ?? false
      if result {
        doThisAfter(0.3) {
          Task {
            await self.refreshPost()
          }
        }
      }
      return result
    }
    return false
  }
  
  func refreshPost(sort: CommentSortOption = .confidence, after: String? = nil, subreddit: String? = nil, full: Bool = true) async -> ([Comment]?, String?)? {
    if let subreddit = data?.subreddit ?? subreddit, let response = await redditAPI.fetchPost(subreddit: subreddit, postID: id) {
      if let post = response[0] {
        switch post {
        case .first(let actualData):
          if full {
            await MainActor.run {
              let newData = actualData.data?.children?[0].data
              self.data = newData
            }
          }
        case .second(_):
          break
        }
      }
      if let comments = response[1] {
        switch comments {
        case .first(_):
          return nil
        case .second(let actualData):
          if let data = actualData.data {
            return (data.children?.map { x in
              if let data = x.data {
                return Comment(data: data, api: redditAPI)
              } else {
                return nil
              }
            }.compactMap { $0 }, data.after)
          }
        }
      }
    }
    return nil
  }
  
  func vote(action: RedditAPI.VoteAction) async -> Bool? {
    let oldLikes = data?.likes
    let oldUps = data?.ups ?? 0
    var newAction = action
    newAction = action.boolVersion() == oldLikes ? .none : action
    await MainActor.run { [newAction] in
      data?.likes = newAction.boolVersion()
      data?.ups = oldUps + (action.boolVersion() == oldLikes ? oldLikes == nil ? 0 : -action.rawValue : action.rawValue * (oldLikes == nil ? 1 : 2))
    }
    let result = await redditAPI.vote(newAction, id: "\(typePrefix ?? "")\(id)")
    if result == nil || !result! {
      await MainActor.run {
        data?.likes = oldLikes
        data?.ups = oldUps
      }
    }
    return result
  }
}

struct PostData: GenericRedditEntityDataType, Defaults.Serializable {
  let subreddit: String
  let selftext: String
  let author_fullname: String?
  let saved: Bool
  let gilded: Int
  let clicked: Bool
  let title: String
  let subreddit_name_prefixed: String
  let hidden: Bool
  var ups: Int
  var downs: Int
  let hide_score: Bool
  let name: String
  let quarantine: Bool
  let link_flair_text_color: String?
  let upvote_ratio: Double
  let subreddit_type: String
  let total_awards_received: Int
  let is_self: Bool
  let created: Double
  let domain: String
  let allow_live_comments: Bool
  let selftext_html: String?
  let id: String
  let is_robot_indexable: Bool
  let author: String
  let num_comments: Int
  let send_replies: Bool
  let whitelist_status: String?
  let contest_mode: Bool
  let permalink: String
  let url: String
  let subreddit_subscribers: Int
  let created_utc: Double?
  let num_crossposts: Int
  let is_video: Bool
  
  // Optional properties
  let wls: Int?
  let pwls: Int?
  let link_flair_text: String?
  let thumbnail: String?
  //  let edited: Edited?
  let link_flair_template_id: String?
  let author_flair_text: String?
  //    let media: String?
  let approved_at_utc: Int?
  let mod_reason_title: String?
  let top_awarded_type: String?
  let author_flair_background_color: String?
  let approved_by: String?
  let is_created_from_ads_ui: Bool?
  let author_premium: Bool?
  let author_flair_css_class: String?
  let gildings: [String: Int]?
  let content_categories: [String]?
  let mod_note: String?
  let link_flair_type: String?
  let removed_by_category: String?
  let banned_by: String?
  let author_flair_type: String?
  var likes: Bool?
  let suggested_sort: String?
  let banned_at_utc: String?
  let view_count: String?
  let archived: Bool?
  let no_follow: Bool?
  let is_crosspostable: Bool?
  let pinned: Bool?
  let over_18: Bool?
  //  let all_awardings: [Awarding]?
  let awarders: [String]?
  let media_only: Bool?
  let can_gild: Bool?
  let spoiler: Bool?
  let locked: Bool?
  let treatment_tags: [String]?
  let visited: Bool?
  let removed_by: String?
  let num_reports: Int?
  let distinguished: String?
  let subreddit_id: String?
  let author_is_blocked: Bool?
  let mod_reason_by: String?
  let removal_reason: String?
  let link_flair_background_color: String?
  let report_reasons: [String]?
  let discussion_type: String?
  let secure_media: Either<SecureMediaRedditVideo, SecureMediaAlt>?
  let secure_media_embed: SecureMediaEmbed?
}

struct SecureMediaAlt: Codable, Hashable {
  let type: String?
  let oembed: Oembed?
}

struct Oembed: Codable, Hashable {
  let provider_url: String?
  let version: String?
  let title: String?
  let type: String?
  let thumbnail_width: Int?
  let height: Int?
  let width: Int?
  let html: String?
  let author_name: String?
  let provider_name: String?
  let thumbnail_url: String?
  let thumbnail_height: Int?
  let author_url: String?
}

struct SecureMediaEmbed: Codable, Hashable {
  let content: String?
  let width: Int?
  let scrolling: Bool?
  let media_domain_url: String?
  let height: Int?
}

struct RedditVideo: Codable, Hashable {
  let bitrate_kbps: Int?
  let fallback_url: String?
  let has_audio: Bool?
  let height: Int?
  let width: Int?
  let scrubber_media_url: String?
  let dash_url: String?
  let duration: Int?
  let hls_url: String?
  let is_gif: Bool?
  let transcoding_status: String?
}

struct SecureMediaRedditVideo: Codable, Hashable {
  let reddit_video: RedditVideo?
}

struct Awarding: Codable, Hashable {
  let id: String
  let name: String
  let description: String
  let coin_price: Int
  let coin_reward: Int
  let icon_url: String
  let is_enabled: Bool
  let count: Int
  
  // Optional properties
  let days_of_premium: Int?
  let award_sub_type: String?
  let days_of_drip_extension: Int?
  let icon_height: Int?
  let icon_width: Int?
  let is_new: Bool?
  let subreddit_coin_reward: Int?
  let tier_by_required_awardings: [String: Int]?
  let award_type: String?
  let awardings_required_to_grant_benefits: Int?
  let start_date: Double?
  let end_date: Double?
  let static_icon_height: Int?
  let static_icon_url: String?
  let static_icon_width: Int?
  let subreddit_id: String?
}

enum Edited: Codable {
  case bool(Bool)
  case double(Double)
  
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let boolValue = try? container.decode(Bool.self) {
      self = .bool(boolValue)
    } else if let doubleValue = try? container.decode(Double.self) {
      self = .double(doubleValue)
    } else {
      throw DecodingError.typeMismatch(Edited.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected value of type Bool or Double"))
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .bool(let boolValue):
      try container.encode(boolValue)
    case .double(let doubleValue):
      try container.encode(doubleValue)
    }
  }
}
