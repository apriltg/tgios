module Tgios
  module ModelErrorsHelper
    def has_error_in_fields_and_errors_for_name(fields, errors, field_name)
      if errors.is_a?(Hash)
        errors.has_key?(field_name) || errors.has_key?(related_name_in_fields(fields, field_name))
      else
        false
      end
    end

    def related_name_in_fields(fields, field_name)
      field = fields.find{|fld| fld[:name] == field_name}
      if field.is_a?(Hash)
        field[:related_name]
      else
        nil
      end
    end
  end
end