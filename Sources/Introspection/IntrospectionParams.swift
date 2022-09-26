import Foundation

public struct IntrospectionParams {
  let content: Content
  let contentHeroImageURL: String?
  let userID: String?
  let logUserID: String?
  let scopeFilter: String?

  public init(
    content: Content,
    contentHeroImageURL: String?,
    userID: String?,
    logUserID: String?,
    scopeFilter: String?
  ) {
    self.content = content
    self.contentHeroImageURL = contentHeroImageURL
    self.userID = userID
    self.logUserID = logUserID
    self.scopeFilter = scopeFilter
  }
}
