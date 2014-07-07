module Tgios
  module CustomMethod
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end

    end

    def on(event_name, &block)
      @events[event_name]=block.weak!
    end

    def off(*event_names)
      event_names.each {|event_name| @events.delete(event_name) }
    end

    module ClassMethods
      def define_custom_method(name=[])
        name.each do |fld|
          define_method fld do
            self.instance_variable_get(:"@#{fld}")
          end
          define_method "#{fld}=" do |value|
            old_value=self.instance_variable_get(:"@#{fld}")
            self.instance_variable_set(:"@#{fld}", value)
            @events[:value_changed].call(self, fld, old_value, value) unless @events.nil? || @events[:value_changed].nil?
          end

        end
      end
    end
  end

end