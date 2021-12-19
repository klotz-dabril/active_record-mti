# frozen_string_literal: true

require 'spec_helper'
require 'helpers/database_setup'

RSpec.describe ActiveRecord::MTI do
  it "has a version number" do
    expect(ActiveRecord::MTI::VERSION).not_to be nil
  end


  describe 'public interface' do 
    it 'delegates the getter' do
      record    = BaseWithCompanion.new
      companion = Companion.new string_field_from_companion: 'some_string'

      record.companion = companion

      expect(record.string_field_from_companion).to eq('some_string')
    end


    it 'delegates the setter' do
      record = BaseWithCompanion.new
      record.string_field_from_companion = 'some_string'

      companion = record.companion

      expect(companion.string_field_from_companion).to eq('some_string')
    end


    it 'persists the companion record' do
      record    = BaseWithCompanion.new
      companion = Companion.new string_field_from_companion: 'some_string'

      record.companion = companion
      record.save!

      expect(companion.persisted?).to be(true)
    end


    it 'accepts companion attributes when instanciating' do
      record    = BaseWithCompanion.new string_field_from_companion: 'some_string'
      companion = record.companion

      expect(companion.string_field_from_companion).to eq('some_string')
    end


    it 'destroys the companion record' do
      companion    = Companion.create!
      companion_id = companion.id

      record = BaseWithCompanion.create! companion_id: companion_id
      record.destroy!

      expect(Companion.where(id: companion_id)).to be_empty
    end


    it 'does not create the companion before it\'s required' do
      record = BaseWithCompanion.new
      record.save

      expect(record.companion).to be_nil
    end


    it 'marks record as changed when companion changes' do
      record    = BaseWithCompanion.new
      companion = Companion.new string_field_from_companion: 'some_string'

      record.companion = companion
      record.save!

      expect(record.changed?).to be(false)

      record.companion.string_field_from_companion = 'different_string'

      expect(record.changed?).to be(true)
    end


    it 'reports companion\'s changed attributes' do
      record    = BaseWithCompanion.new
      companion = Companion.new string_field_from_companion: 'some_string'

      record.companion = companion
      record.save!

      expect(record.changed_attributes).to be_empty

      record.companion.string_field_from_companion = 'different_string'

      expect(record.changed_attributes).to eq({
        "string_field_from_companion" => "some_string"
      })
    end
  end
end
