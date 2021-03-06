unless defined?(DM)
  DM = DataMapper::Types
end

require 'date'
require 'time'
require 'bigdecimal'

module DataMapper

  # :include:QUICKLINKS
  #
  # = Properties
  # Properties for a model are not derived from a database structure, but
  # instead explicitly declared inside your model class definitions. These
  # properties then map (or, if using automigrate, generate) fields in your
  # repository/database.
  #
  # If you are coming to DataMapper from another ORM framework, such as
  # ActiveRecord, this is a fundamental difference in thinking. However, there
  # are several advantages to defining your properties in your models:
  #
  # * information about your model is centralized in one place: rather than
  #   having to dig out migrations, xml or other configuration files.
  # * having information centralized in your models, encourages you and the
  #   developers on your team to take a model-centric view of development.
  # * it provides the ability to use Ruby's access control functions.
  # * and, because DataMapper only cares about properties explicitly defined in
  #   your models, DataMapper plays well with legacy databases, and shares
  #   databases easily with other applications.
  #
  # == Declaring Properties
  # Inside your class, you call the property method for each property you want
  # to add. The only two required arguments are the name and type, everything
  # else is optional.
  #
  #   class Post
  #     include DataMapper::Resource
  #     property :title,   String,    :nullable => false
  #        # Cannot be null
  #     property :publish, TrueClass, :default => false
  #        # Default value for new records is false
  #   end
  #
  # By default, DataMapper supports the following primitive types:
  #
  # * TrueClass, Boolean
  # * String
  # * Text (limit of 65k characters by default)
  # * Float
  # * Integer
  # * BigDecimal
  # * DateTime
  # * Date
  # * Time
  # * Object (marshalled out during serialization)
  # * Class (datastore primitive is the same as String. Used for Inheritance)
  #
  # For more information about available Types, see DataMapper::Type
  #
  # == Limiting Access
  # Property access control is uses the same terminology Ruby does. Properties
  # are public by default, but can also be declared private or protected as
  # needed (via the :accessor option).
  #
  #  class Post
  #   include DataMapper::Resource
  #    property :title,  String,                  :accessor => :private
  #      # Both reader and writer are private
  #    property :body,   Text, :accessor => :protected
  #      # Both reader and writer are protected
  #  end
  #
  # Access control is also analogous to Ruby accessors and mutators, and can
  # be declared using :reader and :writer, in addition to :accessor.
  #
  #  class Post
  #    include DataMapper::Resource
  #
  #    property :title, String, :writer => :private
  #      # Only writer is private
  #
  #    property :tags,  String, :reader => :protected
  #      # Only reader is protected
  #  end
  #
  # == Overriding Accessors
  # The accessor for any property can be overridden in the same manner that Ruby
  # class accessors can be.  After the property is defined, just add your custom
  # accessor:
  #
  #  class Post
  #    include DataMapper::Resource
  #    property :title,  String
  #
  #    def title=(new_title)
  #      raise ArgumentError if new_title != 'Luke is Awesome'
  #      @title = new_title
  #    end
  #  end
  #
  # == Lazy Loading
  # By default, some properties are not loaded when an object is fetched in
  # DataMapper. These lazily loaded properties are fetched on demand when their
  # accessor is called for the first time (as it is often unnecessary to
  # instantiate -every- property -every- time an object is loaded).  For
  # instance, DataMapper::Types::Text fields are lazy loading by default,
  # although you can over-ride this behavior if you wish:
  #
  # Example:
  #
  #  class Post
  #    include DataMapper::Resource
  #    property :title,  String                    # Loads normally
  #    property :body,   DataMapper::Types::Text   # Is lazily loaded by default
  #  end
  #
  # If you want to over-ride the lazy loading on any field you can set it to a
  # context or false to disable it with the :lazy option. Contexts allow
  # multipule lazy properties to be loaded at one time. If you set :lazy to
  # true, it is placed in the :default context
  #
  #  class Post
  #    include DataMapper::Resource
  #
  #    property :title,    String
  #      # Loads normally
  #
  #    property :body,     DataMapper::Types::Text, :lazy => false
  #      # The default is now over-ridden
  #
  #    property :comment,  String, lazy => [:detailed]
  #      # Loads in the :detailed context
  #
  #    property :author,   String, lazy => [:summary,:detailed]
  #      # Loads in :summary & :detailed context
  #  end
  #
  # Delaying the request for lazy-loaded attributes even applies to objects
  # accessed through associations. In a sense, DataMapper anticipates that
  # you will likely be iterating over objects in associations and rolls all
  # of the load commands for lazy-loaded properties into one request from
  # the database.
  #
  # Example:
  #
  #   Widget[1].components
  #     # loads when the post object is pulled from database, by default
  #
  #   Widget[1].components.first.body
  #     # loads the values for the body property on all objects in the
  #     # association, rather than just this one.
  #
  #   Widget[1].components.first.comment
  #     # loads both comment and author for all objects in the association
  #     # since they are both in the :detailed context
  #
  # == Keys
  # Properties can be declared as primary or natural keys on a table.
  # You should a property as the primary key of the table:
  #
  # Examples:
  #
  #  property :id,        Integer, :serial => true  # auto-incrementing key
  #  property :legacy_pk, String, :key => true      # 'natural' key
  #
  # This is roughly equivalent to ActiveRecord's <tt>set_primary_key</tt>,
  # though non-integer data types may be used, thus DataMapper supports natural
  # keys. When a property is declared as a natural key, accessing the object
  # using the indexer syntax <tt>Class[key]</tt> remains valid.
  #
  #   User[1]
  #      # when :id is the primary key on the users table
  #   User['bill']
  #      # when :name is the primary (natural) key on the users table
  #
  # == Indeces
  # You can add indeces for your properties by using the <tt>:index</tt>
  # option. If you use <tt>true</tt> as the option value, the index will be 
  # automatically named. If you want to name the index yourself, use a symbol
  # as the value.
  #
  #   property :last_name,  String, :index => true
  #   property :first_name, String, :index => :name
  # 
  # You can create multi-column composite indeces by using the same symbol in
  # all the columns belonging to the index. The columns will appear in the
  # index in the order they are declared.
  #
  #   property :last_name,  String, :index => :name
  #   property :first_name, String, :index => :name
  #      # => index on (last_name, first_name)
  # 
  # If you want to make the indeces unique, use <tt>:unique_index</tt> instead
  # of <tt>:index</tt>
  #
  # == Inferred Validations
  # If you require the dm-validations plugin, auto-validations will
  # automatically be mixed-in in to your model classes:
  # validation rules that are inferred when properties are declared with
  # specific column restrictions.
  #
  #  class Post
  #    include DataMapper::Resource
  #
  #    property :title, String, :length => 250
  #      # => infers 'validates_length :title,
  #             :minimum => 0, :maximum => 250'
  #
  #    property :title, String, :nullable => false
  #      # => infers 'validates_present :title
  #
  #    property :email, String, :format => :email_address
  #      # => infers 'validates_format :email, :with => :email_address
  #
  #    property :title, String, :length => 255, :nullable => false
  #      # => infers both 'validates_length' as well as
  #      #    'validates_present'
  #      #    better: property :title, String, :length => 1..255
  #
  #  end
  #
  # This functionality is available with the dm-validations gem, part of the
  # dm-more bundle. For more information about validations, check the
  # documentation for dm-validations.
  #
  # == Embedded Values
  # As an alternative to extraneous has_one relationships, consider using an
  # EmbeddedValue.
  #
  # == Misc. Notes
  # * Properties declared as strings will default to a length of 50, rather than
  #   255 (typical max varchar column size).  To overload the default, pass
  #   <tt>:length => 255</tt> or <tt>:length => 0..255</tt>.  Since DataMapper
  #   does not introspect for properties, this means that legacy database tables
  #   may need their <tt>String</tt> columns defined with a <tt>:length</tt> so
  #   that DM does not apply an un-needed length validation, or allow overflow.
  # * You may declare a Property with the data-type of <tt>Class</tt>.
  #   see SingleTableInheritance for more on how to use <tt>Class</tt> columns.
  class Property

    # NOTE: check is only for psql, so maybe the postgres adapter should
    # define its own property options. currently it will produce a warning tho
    # since PROPERTY_OPTIONS is a constant
    #
    # NOTE: PLEASE update PROPERTY_OPTIONS in DataMapper::Type when updating
    # them here
    PROPERTY_OPTIONS = [
      :public, :protected, :private, :accessor, :reader, :writer,
      :lazy, :default, :nullable, :key, :serial, :field, :size, :length,
      :format, :index, :unique_index, :check, :ordinal, :auto_validation,
      :validates, :unique, :lock, :track, :scale, :precision
    ]

    # FIXME: can we pull the keys from
    # DataMapper::Adapters::DataObjectsAdapter::TYPES
    # for this?
    TYPES = [
      TrueClass,
      String,
      DataMapper::Types::Text,
      Float,
      Integer,
      BigDecimal,
      DateTime,
      Date,
      Time,
      Object,
      Class,
      DataMapper::Types::Discriminator
    ]

    VISIBILITY_OPTIONS = [ :public, :protected, :private ]

    DEFAULT_LENGTH    = 50
    DEFAULT_SCALE     = 10
    DEFAULT_PRECISION = 0

    attr_reader :primitive, :model, :name, :instance_variable_name,
      :type, :reader_visibility, :writer_visibility, :getter, :options,
      :default, :precision, :scale

    # Supplies the field in the data-store which the property corresponds to
    #
    # @return <String> name of field in data-store
    # -
    # @api semi-public
    def field(*args)
      @options.fetch(:field, repository(*args).adapter.field_naming_convention.call(name))
    end

    def unique
      @unique ||= @options.fetch(:unique, @serial || @key || false)
    end

    def repository(*args)
      @model.repository(*args)
    end

    def hash
      if @custom && !@bound
        @type.bind(self)
        @bound = true
      end

      return @model.hash + @name.hash
    end

    def eql?(o)
      if o.is_a?(Property)
        return o.model == @model && o.name == @name
      else
        return false
      end
    end

    def length
      @length.is_a?(Range) ? @length.max : @length
    end
    alias size length

    def index
      @index
    end

    def unique_index
      @unique_index
    end

    # Returns whether or not the property is to be lazy-loaded
    #
    # @return <TrueClass, FalseClass> whether or not the property is to be
    #   lazy-loaded
    # -
    # @api public
    def lazy?
      @lazy
    end


    # Returns whether or not the property is a key or a part of a key
    #
    # @return <TrueClass, FalseClass> whether the property is a key or a part of
    #   a key
    #-
    # @api public
    def key?
      @key
    end

    # Returns whether or not the property is "serial" (auto-incrementing)
    #
    # @return <TrueClass, FalseClass> whether or not the property is "serial"
    #-
    # @api public
    def serial?
      @serial
    end

    # Returns whether or not the property can accept 'nil' as it's value
    #
    # @return <TrueClass, FalseClass> whether or not the property can accept 'nil'
    #-
    # @api public
    def nullable?
      @nullable
    end

    def lock?
      @lock
    end

    def custom?
      @custom
    end

    # Provides a standardized getter method for the property
    #
    # @raise <ArgumentError> "+resource+ should be a DataMapper::Resource, but was ...."
    #-
    # @api private
    def get(resource)
      raise ArgumentError, "+resource+ should be a DataMapper::Resource, but was #{resource.class}" unless Resource === resource
      resource.attribute_get(@name)
    end

    # Provides a standardized setter method for the property
    #
    # @raise <ArgumentError> "+resource+ should be a DataMapper::Resource, but was ...."
    #-
    # @api private
    def set(resource, value)
      raise ArgumentError, "+resource+ should be a DataMapper::Resource, but was #{resource.class}" unless Resource === resource
      resource.attribute_set(@name, value)
    end

    # typecasts values into a primitive
    #
    # @return <TrueClass, String, Float, Integer, BigDecimal, DateTime, Date, Time
    #   Class> the primitive data-type, defaults to TrueClass
    #-
    # @private
    def typecast(value)
      return value if type === value || (value.nil? && type != TrueClass)

      if    type == TrueClass  then %w[ true 1 t ].include?(value.to_s.downcase)
      elsif type == String     then value.to_s
      elsif type == Float      then value.to_f
      elsif type == Integer    then value.to_i
      elsif type == BigDecimal then BigDecimal(value.to_s)
      elsif type == DateTime   then DateTime.parse(value.to_s)
      elsif type == Date       then Date.parse(value.to_s)
      elsif type == Time       then Time.parse(value.to_s)
      elsif type == Class      then find_const(value)
      end
    end

    def default_for(resource)
      @default.respond_to?(:call) ? @default.call(resource, self) : @default
    end

    def inspect
      "#<Property:#{@model}:#{@name}>"
    end

    private

    def initialize(model, name, type, options = {})
      if Fixnum == type
        # It was decided that Integer is a more expressively names class to
        # use instead of Fixnum.  Fixnum only represents smaller numbers,
        # so there was some confusion over whether or not it would also
        # work with Bignum too (it will).  Any Integer, which includes
        # Fixnum and Bignum, can be stored in this property.
        warn "#{type} properties are deprecated.  Please use Integer instead"
        type = Integer
      end

      raise ArgumentError, "+model+ is a #{model.class}, but is not a type of Resource"                 unless Resource > model
      raise ArgumentError, "+name+ should be a Symbol, but was #{name.class}"                           unless Symbol === name
      raise ArgumentError, "+type+ was #{type.inspect}, which is not a supported type: #{TYPES * ', '}" unless TYPES.include?(type) || (DataMapper::Type > type && TYPES.include?(type.primitive))

      if (unknown_options = options.keys - PROPERTY_OPTIONS).any?
        raise ArgumentError, "+options+ contained unknown keys: #{unknown_options * ', '}"
      end

      @model                  = model
      @name                   = name.to_s.sub(/\?$/, '').to_sym
      @type                   = type
      @custom                 = DataMapper::Type > @type
      @options                = @custom ? @type.options.merge(options) : options
      @instance_variable_name = "@#{@name}"

      # TODO: This default should move to a DataMapper::Types::Text
      # Custom-Type and out of Property.
      @primitive = @options.fetch(:primitive, @type.respond_to?(:primitive) ? @type.primitive : @type)

      @getter   = TrueClass == @primitive ? "#{@name}?".to_sym : @name
      @lock     = @options.fetch(:lock,     false)
      @serial   = @options.fetch(:serial,   false)
      @key      = @options.fetch(:key,      @serial || false)
      @default  = @options.fetch(:default,  nil)
      @nullable = @options.fetch(:nullable, @key == false && @default.nil?)
      @index    = @options.fetch(:index,    false)
      @unique_index = @options.fetch(:unique_index, false)

      @lazy     = @options.fetch(:lazy,     @type.respond_to?(:lazy) ? @type.lazy : false) && !@key

      # assign attributes per-type
      if String == @primitive || Class == @primitive
        @length = @options.fetch(:length, @options.fetch(:size, DEFAULT_LENGTH))
      elsif BigDecimal == @primitive || Float == @primitive
        @scale     = @options.fetch(:scale,     DEFAULT_SCALE)
        @precision = @options.fetch(:precision, DEFAULT_PRECISION)
      end

      determine_visibility

      create_getter
      create_setter

      @model.auto_generate_validations(self) if @model.respond_to?(:auto_generate_validations)
      @model.property_serialization_setup(self) if @model.respond_to?(:property_serialization_setup)

    end

    def determine_visibility # :nodoc:
      @reader_visibility = @options[:reader] || @options[:accessor] || :public
      @writer_visibility = @options[:writer] || @options[:accessor] || :public
      @writer_visibility = :protected if @options[:protected]
      @writer_visibility = :private   if @options[:private]
      raise ArgumentError, "property visibility must be :public, :protected, or :private" unless VISIBILITY_OPTIONS.include?(@reader_visibility) && VISIBILITY_OPTIONS.include?(@writer_visibility)
    end

    # defines the getter for the property
    def create_getter
      @model.class_eval <<-EOS, __FILE__, __LINE__
        #{reader_visibility}
        def #{@getter}
          attribute_get(#{name.inspect})
        end
      EOS

      if @primitive == TrueClass && !@model.instance_methods.include?(@name.to_s)
        @model.class_eval <<-EOS, __FILE__, __LINE__
          #{reader_visibility}
          alias #{@name} #{@getter}
        EOS
      end
    end

    # defines the setter for the property
    def create_setter
      @model.class_eval <<-EOS, __FILE__, __LINE__
        #{writer_visibility}
        def #{name}=(value)
          attribute_set(#{name.inspect}, value)
        end
      EOS
    end
  end # class Property
end # module DataMapper
