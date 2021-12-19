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


module Migrations
  class BaseMigration < ActiveRecord::Migration[7.0]
  end

  class CreateBases < BaseMigration
    def table_name
      :bases
    end

    def change
      create_table table_name do |t|
        t.references :companion, polymorphic: true

        t.timestamps
      end
    end
  end


  class CreateCompanions < BaseMigration
    def table_name
      :companions
    end

    def change
      create_table table_name do |t|
        t.string  :string_field_from_companion
        t.integer :int_field_from_companion

        t.timestamps
      end
    end
  end


  class CreateOtherCompanions < BaseMigration
    def table_name
      :other_companions
    end

    def change
      create_table :other_companions do |t|
        t.string :field_a
        t.string :field_b

        t.timestamps
      end
    end
  end
end


MIGRATION_CLASSES = [
  Migrations::CreateBases,
  Migrations::CreateCompanions,
  Migrations::CreateOtherCompanions
]

MIGRATION_CLASSES.map do |migration_class|
  migration_class.new
end.each do |migration|
  unless ActiveRecord::Base.connection.tables.include? migration.table_name.to_s
    migration.change
  end
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


class BaseWithCompanion < Base
  set_mti_companion :int_field_from_companion,
                    :string_field_from_companion,
                    to:         :companion,
                    class_name: 'Companion'
end


class BaseWithOtherCompanion < Base
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
