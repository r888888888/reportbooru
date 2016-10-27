module Reports
  def generate_all
    [Artists, ContributorUploads, MemberUploads, PostAppeals, PostChanges, PostFlags, Notes, Taggers, WikiPages].each do |model|
      model.new.generate
    end
  end

  module_function :generate_all
end
