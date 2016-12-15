module Archive
  class PoolVersion < ActiveRecord::Base
    establish_connection "archive_#{Rails.env}".to_sym

    %w(execute select_value select_values select_all).each do |method_name|
      define_method("#{method_name}_sql") do |sql, *params|
        self.class.connection.__send__(method_name, self.class.sanitize_sql_array([sql, *params]))
      end

      self.class.__send__(:define_method, "#{method_name}_sql") do |sql, *params|
        connection.__send__(method_name, sanitize_sql_array([sql, *params]))
      end
    end
    
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
end
