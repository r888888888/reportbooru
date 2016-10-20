module Reports
  def generate_all
    [ContributorUploads, MemberUploads, PostAppeals, Notes, Taggers].each do |model|
      model.new.generate
    end
  end

  module_function :generate_all
end
