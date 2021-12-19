# frozen_string_literal: true


require 'active_record'
require 'sqlite3'
require 'logger'


ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.configurations = {
  'development' => {
    'adapter' => 'sqlite3',
    'database' => 'spec/fixtures/data.sqlite3'
  }
}
ActiveRecord::Base.establish_connection(:test)


class Schema < ActiveRecord::Migration[7.0]
  def change
    create_table :bases do |t|
      t.string     :type
      t.references :detail, polymorphic: true

      t.timestamps
    end


    create_table :companions do |t|
      t.string :string_field
      t.int    :int_field

      t.timestamps
    end


    create_table :other_companions do |t|
      t.string :field_a
      t.string :field_b

      t.timestamps
    end
  end
end


unless ActiveRecord::Base.connection.tables.include? 'parents'
  Schema.new.change
end


class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end


class BaseCompanion < ApplicationRecord
  self.abstract_class = true

  has_one :base_record, as: :companion
end


class Companion < BaseCompanion
end


class OtherCompanion < BaseCompanion
end


class Base < ApplicationRecord
  include ActiveRecord::MTI

  set_mti_base :companion
end


class BaseWithCompanion < Parent
  set_mti_companion :int_field_from_companion,
                    :string_field_from_companion,
                    to:         :companion,
                    class_name: 'Companion'
end


class BaseWithOtherCompanion < Parent
  set_mti_companion :field_a,
                    :field_b,
                    to:         :companion,
                    class_name: 'OtherCompanion'
end

RSpec.configure do |config|
  config.around(:example) do |ex|
    ApplicationRecord.transaction do
      ex.run

      raise ActiveRecord::Rollback, 'Database reset after rspec example.'
    end
  end
end
