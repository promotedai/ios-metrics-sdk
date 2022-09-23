import Foundation

public struct IntrospectionParams {
  let content: Content
  let contentHeroImageURL: String?
  let userID: String?
  let logUserID: String?

  public init(
    content: Content,
    contentHeroImageURL: String?,
    userID: String?,
    logUserID: String?
  ) {
    self.content = content
    self.contentHeroImageURL = contentHeroImageURL
    self.userID = userID
    self.logUserID = logUserID
  }
}
