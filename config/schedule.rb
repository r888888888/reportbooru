every 1.day do
  runner "HitCounter.new.prune!"
end

every :sunday, :at => "1:00 am" do
  runner "BigQuery::Tag.new.export!"
end

every :sunday, :at => "2:00 am" do
  runner "BigQuery::User.new.export!"
end

every :sunday, :at => "3:00 am" do
  runner "Reports::PostChanges.new.generate"
end

every :sunday, :at => "4:00 am" do
  runner "Reports::MemberUploads.new.generate"
end
