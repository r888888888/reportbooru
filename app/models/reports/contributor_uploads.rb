module Reports
  class ContributorUploads < Uploads
    def version
      1
    end

    def min_uploads
      300
    end

    def folder_id
      "0B1OwQUUumteuU1RFakdaVmM1clk"
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Contributor Upload Report
    %style
      :css
        #{pure_css_tables}
  %body
    %table{:class => "pure-table pure-table-bordered pure-table-striped"}
      %caption Unlimited uploaders over past thirty days (minium uploads is #{min_uploads})
      %thead
        %tr
          %th User
          %th Total
          %th Del
          %th Par
          %th Src
          %th S
          %th Q
          %th E
          %th Gen
          %th Char
          %th Copy
          %th Art
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
            %td= datum[:queue_bypass]
            %td= datum[:deleted]
            %td= datum[:source]
            %td= datum[:safe]
            %td= datum[:questionable]
            %td= datum[:explicit]
            %td= datum[:general]
            %td= datum[:character]
            %td= datum[:copyright]
            %td= datum[:artist]
EOS
    end

    def candidates
      DanbooruRo::User.joins("join posts on posts.uploader_id = users.id").where("posts.created_at >= ? and users.bit_prefs & ? > 0", date_window, 1 << 14).group("users.id").having("count(*) > ?", min_uploads).pluck("distinct(users.id)")
    end
  end
end
