# Activerecord::Mti





## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-mti'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install activerecord-mti

## Setup

### Simple migration
 ```ruby
 class MTIExampleMigration < ActiveRecord::Migration[5.2]
   create_table :bases do |t|
     t.references :companion, polymorphic: true
 
     t.timestamps
   end
 
   create_table :companions do |t|
     t.string  :string_field_from_companion
     t.integer :int_field_from_companion
 
     t.timestamps
   end
 
   create_table :other_companions do |t|
     t.string :field_a
     t.string :field_b
 
     t.timestamps
   end
 end
```


### Models

#### Model for the agregated tables
```ruby
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
```

## Usage

```ruby
 base_with_companion = BaseWithCompanion.create string_field_from_companion: 'some_string'
 base_with_companion.companion_type # 'BaseWithCompanion'
 base_with_companion.string_field_from_companion # some_string

 base_with_companion.string_field_from_companion = 'other_value'
 base_with_companion.changed? # true

 base_with_companion.save!
 base_with_companion.changed? # false

 base_with_companion.destroy # also destroys the associated CompanionOne record
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/klotz-dabril/activerecord-mti.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
