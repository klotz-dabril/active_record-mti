# frozen_string_literal: true

require_relative "mti/version"

module ActiveRecord
  ##
  # = Example Setup
  #
  # == Simple migration
  #  class MTIExampleMigration < ActiveRecord::Migration[5.2]
  #    create_table :bases do |t|
  #      t.references :companion, polymorphic: true
  #  
  #      t.timestamps
  #    end
  #  
  #    create_table :companions do |t|
  #      t.string  :string_field_from_companion
  #      t.integer :int_field_from_companion
  #  
  #      t.timestamps
  #    end
  #  
  #    create_table :other_companions do |t|
  #      t.string :field_a
  #      t.string :field_b
  #  
  #      t.timestamps
  #    end
  #  end

  #
  # == Models
  #
  # === Model for the agregated tables
  #  class ApplicationRecord < ActiveRecord::Base
  #    self.abstract_class = true
  #  end
  #
  #
  #  class BaseCompanion < ApplicationRecord
  #    self.abstract_class = true
  #
  #    has_one :base_record, as: :companion
  #  end
  #
  #
  #  class Companion < BaseCompanion
  #  end
  #
  #
  #  class OtherCompanion < BaseCompanion
  #  end
  #
  #
  #  class Base < ApplicationRecord
  #    include ActiveRecord::MTI
  #
  #    set_mti_base :companion
  #  end
  #
  #
  #  class BaseWithCompanion < Base
  #    set_mti_companion :int_field_from_companion,
  #                      :string_field_from_companion,
  #                      to:         :companion,
  #                      class_name: 'Companion'
  #  end
  #
  #
  #  class BaseWithOtherCompanion < Base
  #    set_mti_companion :field_a,
  #                      :field_b,
  #                      to:         :companion,
  #                      class_name: 'OtherCompanion'
  #  end
  #
  #
  # = Usage
  #
  #  base_with_companion = BaseWithCompanion.create string_field_from_companion: 'some_string'
  #  base_with_companion.companion_type # 'BaseWithCompanion'
  #  base_with_companion.string_field_from_companion # some_string
  #
  #  base_with_companion.string_field_from_companion = 'other_value'
  #  base_with_companion.changed? # true
  #
  #  base_with_companion.save!
  #  base_with_companion.changed? # false
  #
  #  base_with_companion.destroy # also destroys the associated CompanionOne record
  #
  #
  #
  module MTI
    module ClassMethods
      def set_mti_base(association)
        belongs_to association,
                   polymorphic: true,
                   dependent:   :destroy,
                   autosave:    true
      end


      def set_mti_companion(*attributes, to:, class_name:)
        belongs_to to,
                   class_name: class_name,
                   dependent:  :destroy,
                   autosave:   true


        build_companion_method = define_method(:"build_#{to}") do
          super()

          companion = self.send(to)
          self.send(:"#{to}_type=", companion.class.name)

          companion
        end


        lazily_built_companion_method = define_method(:"lazily_built_#{to}") do
          send(to) || send(build_companion_method)
        end


        define_method(:changed_attributes) do
          companion = self.send(to)

          super().merge(
            companion&.changed_attributes || {}
          )
        end


        define_method(:changed?) do
          companion = self.send(to)

          super() || companion&.changed?
        end


        # getters
        delegate *attributes,
                 to:        to,
                 allow_nil: true


        # setters
        setters = attributes.map { |x| :"#{x}=" }
        delegate *setters,
                 to: lazily_built_companion_method
      end
    end


    def self.included(klass)
      klass.extend ClassMethods
    end
  end
end
