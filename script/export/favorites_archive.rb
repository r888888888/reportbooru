#!/usr/bin/env ruby

require 'date'

date = Date.parse(ARGV[0])

sql = <<EOS
copy (                                                                   
  with posts_in_month as (                                                      
    select id from posts where created_at >= '#{date}' and created_at < (       
      date_trunc('month', '#{date}'::date) + interval '1 month' - interval '1 day'                                                                             
    )::date                                                                     
  ) select id, user_id, post_id from favorites where post_id in (                   
    select id from posts_in_month                                               
  )                                                                             
) to '/tmp/favorites-#{date}.csv' delimiter ','
EOS

exec("psql", "-U", "replication", "danbooru2", "-c", sql)
