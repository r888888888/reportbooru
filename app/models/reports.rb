module Reports
  def generate_all
    [AddRequestTags, Approvers, ArtistCommentaries, Artists, BulkUpdateRequests, Comments, ContributorUploads, DownVotes, ForumPosts, ForumTopics, InactiveApprovers, MemberUploads, Pools, PostAppeals, PostChanges, PostFlags, PostReplacements, Notes, SuperVoters, TagAliases, TagImplications, Taggers, TagVandalism, TranslatorTags, WikiPages].each do |model|
    	begin
	      model.new.generate
	    rescue => e
	    	# swallow errors so we can keep going on
	    end
    end
  end

  module_function :generate_all
end
