# AbstractImporter

[![Build Status](https://travis-ci.org/concordia-publishing-house/abstract_importer.png?branch=master)](https://travis-ci.org/concordia-publishing-house/abstract_importer)

[![Code Climate](https://codeclimate.com/github/concordia-publishing-house/abstract_importer.png)](https://codeclimate.com/github/concordia-publishing-house/abstract_importer)

AbstractImporter provides services for importing complex data from an arbitrary data source. It:

 * Preserves relationships between tables that are imported as a set
 * Allows you to extend and modify the import process through a DSL and callbacks
 * Supports partial and idempotent imports
 * Sports flexible reporting and logging



## Getting Started

### Installation

Add this line to your application's `Gemfile`:

    gem 'abstract_importer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install abstract_importer



### Usage

Derive your own importer from `AbstractImporter::Base` and specify the tables you intend to import:

```ruby
class MyImporter < AbstractImporter::Base
  
  import do |import|
    import.students
    import.parents
  end
  
end
```

`AbstractImporter` now knows it must import two collections: `students` and `parents`, in that order. It refers to this as its "Import Plan".


##### Parent and Data Source

`MyImporter`'s initializer takes two arguments: `parent` and `data_source`:

 * `parent` is any object that will respond to the names of your collections with an `ActiveRecord::Relation`.
 * `data_source` is any object that will respond to the names of your collections by yielding a hash of attributes once for every record you should import.

Here are reasonable classes for `parent` and `data_source`:

```ruby
# parent
class Account < ActiveRecord::Base
  has_many :students
  has_many :parents
end
```

```ruby
# data source
class Database
  def students
    yield id: 457, name: "Ron"
    yield id: 458, name: "Ginny"
    yield id: 459, name: "Fred"
    yield id: 460, name: "George"
  end

  def parents
    yield id: 88, name: "Arthur"
    yield id: 89, name: "Molly"
  end
end
```


##### legacy_id

For every record that AbstractImporter creates, it will assign the attribute `legacy_id`.

AbstractImporter uses this value to make sure that we don't import the same record twice in case an import is interrupted and needs to be retried or a user imports their old database more than once.


##### Performing an Import

A straightforward import looks like this:

```ruby
summary = MyImport.new(parent, data_source).perform!
```

AbstractImporter optionally takes a hash of settings as a third argument:

 * `:dry_run` (default: `false`) when set to `true`, goes through all the steps except creating the records
 * `:io` (default: `$stderr`) an IO object that is passed to the reporter
 * `:reporter` (default: `AbstractImporter::Reporter.new(io)`) performs logging in response to various events



### Customizing the Import Plan

You can customize the Import Plan by defining various callbacks on each collection you declare:

```ruby
class MyImporter < AbstractImporter::Base
  
  import do |import|
    import.students do |options|
      options.finder :find_student
      options.before_build { |attrs| attrs.merge(name: attrs[:name].capitalize) }
      options.on_complete :students_completed
    end
    import.parents
  end
  
  def find_student
    ...
  end
  
  def students_completed
    ...
  end
  
end
```

The complete list of callbacks is below.

##### finder

`finder` accepts a hash of attributes for a record to be imported and returns a corresponding record (if one exists). This can be useful for finding an preexisting counterpart to an imported record. (e.g. The user has created the tag "Butterbeer" and tries to import a tag with the same name. Although the legacy "Butterbeer" tag was never imported, it should not be, and any legacy articles associated with it should be associated with the native one.)

##### before_build

`before_build` allows a callback to modify the hash of attributes before it is passed to `ActiveRecord::Relation#build`.

##### before_create

`before_create` allows a callback to modify a record before `save` is called on it.

##### rescue

`rescue` (like `before_create`) is called with a record just before `save` is called. Unlike `before_create`, `rescue` is only called if the record does not pass validations.

##### after_create

`after_create` is called with the original hash of attributes and the newly-saved record right after it is successfully saved.

##### on_complete

`on_complete` is called when all of the records in a collection have been processed.




## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
