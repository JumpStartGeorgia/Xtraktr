module Mongoid
  class Criteria
    def none
      @none = true and self
    end

    def empty_and_chainable?
      !!@none
    end
  end

  module Contextual
    class None
      include ::Enumerable

      # Previously included Queryable, which has been extracted in v4
      attr_reader :collection, :criteria, :klass

      def blank?
        !exists?
      end
      alias :empty? :blank?

      attr_reader :criteria, :klass

      def ==(other)
        other.is_a?(None)
      end

      def each
        if block_given?
          [].each { |doc| yield(doc) }
          self
        else
          to_enum
        end
      end

      def exists?; false; end

      def initialize(criteria)
        @criteria, @klass = criteria, criteria.klass
      end

      def last; nil; end

      def length
        entries.length
      end
      alias :size :length
    end

    private

    def create_context
      return None.new(self) if empty_and_chainable?
      embedded ? Memory.new(self) : Mongo.new(self)
    end
  end

  module Finders
    delegate :none, to: :with_default_scope
  end
end
