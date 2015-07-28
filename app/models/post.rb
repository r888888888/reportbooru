class Post < ActiveRecord::Base
  def preview_file_url
    if !has_preview?
      return "/images/download-preview.png"
    end

    "/data/preview/#{md5}.jpg"
  end

  def is_image?
    file_ext =~ /jpg|jpeg|gif|png/i
  end

  def is_video?
    file_ext =~ /webm/i
  end

  def is_ugoira?
    file_ext =~ /zip/i
  end

  def has_preview?
    is_image? || is_video? || is_ugoira?
  end
end
