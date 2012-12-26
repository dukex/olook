module FactoryGirl
  class AttributeList
    include Enumerable

    def initialize(name = nil)
      @name       = name
      @attributes = []
    end

    def define_attribute(attribute)
      ensure_attribute_not_self_referencing! attribute
      ensure_attribute_not_defined! attribute

      add_attribute attribute
    end

    def each(&block)
      @attributes.each(&block)
    end

    def associations
      @attributes.select(&:association?)
    end

    def apply_attributes(attributes_to_apply)
      attributes_to_apply.each {|attribute| add_attribute(attribute) }
    end

    private

    def add_attribute(attribute)
      @attributes << attribute
      attribute
    end

    def ensure_attribute_not_defined!(attribute)
      if attribute_defined?(attribute.name)
        raise AttributeDefinitionError, "Attribute already defined: #{attribute.name}"
      end
    end

    def ensure_attribute_not_self_referencing!(attribute)
      if attribute.respond_to?(:factory) && attribute.factory == @name
        raise AssociationDefinitionError, "Self-referencing association '#{attribute.name}' in '#{attribute.factory}'"
      end
    end

    def attribute_defined?(attribute_name)
      @attributes.any? do |attribute|
        attribute.name == attribute_name
      end
    end
  end
end
