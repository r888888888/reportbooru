module Reports
  def generate_all
    [ArtistCommentaries, Artists, BulkUpdateRequests, Comments, ContributorUploads, ForumPosts, ForumTopics, MemberUploads, PostAppeals, PostChanges, PostFlags, Notes, TagAliases, TagImplications, Taggers, WikiPages].each do |model|
      model.new.generate
    end
  end

  module_function :generate_all
end
