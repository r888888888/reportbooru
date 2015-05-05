class CreateCounters < ActiveRecord::Migration
  def change
    create_table :counters do |t|
      t.string "key"
      t.text "value"
    end

    add_index "counters", ["key"], :unique => true
  end
end
