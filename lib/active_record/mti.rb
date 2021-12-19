# frozen_string_literal: true

require_relative "mti/version"

module ActiveRecord
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
