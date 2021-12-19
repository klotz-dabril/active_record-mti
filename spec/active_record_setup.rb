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
ActiveRecord::Base.establish_connection(:development)

class Schema < ActiveRecord::Migration[7.0]
  def change
    create_table :parents do |t|
      t.string     :type
      t.references :detail, polymorphic: true

      t.timestamps
    end


    create_table :companions do |t|
      t.string :field_one
      t.string :field_two

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

  has_one :parent, as: :companion
end


class Companion < BaseCompanion
end


class OtherCompanion < BaseCompanion
end


class Parent < ApplicationRecord
  include ActiveRecord::MTI

  set_mti_parent :companion
end


class Child < Parent
  set_mti_child :field_one,
                :field_two,
                to:         :companion,
                class_name: 'Companion'
end


class OtherChild < Parent
  set_mti_child :field_a,
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
