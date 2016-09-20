every 1.day do
  runner "HitCounter.new.prune!"
end

every 1.week do
  runner "BigQuery::Tag.new.export!"
end
