class DanbooruModel < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "danbooru_#{Rails.env}".to_sym

  def readonly?
    true
  end

  def destroy
    raise ReadOnlyRecord
  end

  def delete
    raise ReadOnlyRecord
  end
end
