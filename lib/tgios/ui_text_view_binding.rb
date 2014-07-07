module Tgios
  class UITextViewBinding < BindingBase

    def initialize(model, ui_field, field_name, options={})
      super
      @field_name=field_name
      @options=options
      @events={}
      @ui_field=WeakRef.new(ui_field)
      @model=WeakRef.new(model)
      update_ui_field_style
      assign_value_to_field
    end

    def assign_value_to_field
      val = @model.send(@field_name)
      if val.is_a?(String) || val.nil?
        @ui_field.text=val
      else
        @original_value = val
        @ui_field.text= if val.respond_to?(:round)
                          default_precision = 0
                          default_precision = 6 unless val.is_a?(Integer)
                          val.round((@options[:precision] || default_precision)).to_s
                        else
                          val.to_s
                        end
        @model.send("#{@field_name}=", @ui_field.text)
      end
    end

    def ui_field=(val)
      @ui_field=WeakRef.new(val)
      @ui_field.delegate=self
      update_ui_field_style
      assign_value_to_field
    end

    def model=(val)
      @model=WeakRef.new(val)
      assign_value_to_field
    end

    def update(ui_field, model)
      self.ui_field=ui_field
      self.model=model

    end

    def on(event, &block)
      @events[event]=block.weak!
    end

    #### options
    # type:
    #   :password
    #   :label
    #
    # auto_correct:
    #   true
    #   false
    #   UITextAutocorrectionType
    #
    # auto_capitalize:
    #   true
    #   false
    #   UITextAutocapitalizationType
    #
    # keyboard:
    #   :decimal
    #   uikeyboardtype (sugarcube)
    #   UIKeyboardType
    #
    # precision: Numeric (only useful when value is Numeric)
    #            default:
    #              Integer: 0
    #              Float:   6
    #
    # error:
    #   true
    #   false
    #
    # reduce_font_size:
    #   true
    #   false
    ####

    def update_ui_field_style
      @ui_field.secureTextEntry=@options[:type]==:password
      @ui_field.autocorrectionType = get_auto_correct_type(@options[:auto_correct])
      @ui_field.autocapitalizationType = get_auto_capitalize_type(@options[:auto_capitalize])
      @ui_field.keyboardType = get_keyboard_type(@options[:keyboard])
      @ui_field.enabled = @options[:type] != :label


      text_view_toolbar = PlasticCup::Base.style(UIToolbar.new, frame: CGRectMake(0,0,320,44))
      done_button = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemDone, target: self, action: 'did_return:')

      text_view_toolbar.items=[
          UIBarButtonItem.flexible_space, done_button
      ]
      @ui_field.inputAccessoryView = text_view_toolbar

    end

    def get_auto_capitalize_type(type=nil)
      case type
        when true, nil
          UITextAutocapitalizationTypeSentences
        when false
          UITextAutocapitalizationTypeNone
        else
          type
      end
    end

    def get_auto_correct_type(type=nil)
      case type
        when true
          UITextAutocorrectionTypeYes
        when false
          UITextAutocorrectionTypeNo
        when nil
          UITextAutocorrectionTypeDefault
        else
          type
      end
    end

    def get_keyboard_type(type=nil)
      return type if type.is_a?(Integer)
      ktype = type == :decimal ? :numbers_and_punctuation : type
      (ktype || :default).uikeyboardtype
    end

    def textViewDidEndEditing(field)
      ap 'did_end_editing'
      @model.send("#{@field_name}=", field.text)
      weak_text_field=WeakRef.new(field)
      @events[:end_edit].call(@model, @field_name, {text_field: weak_text_field}) unless @events[:end_edit].nil?

    end

    def did_return(field)
      ap 'did return'
      @ui_field.resignFirstResponder
      weak_text_field=WeakRef.new(@ui_field)
      @events[:return_tapped].call(@model, @field_name, {text_field: weak_text_field}) unless @events[:return_tapped].nil?

    end

    def textViewDidBeginEditing(field)
      ap 'did_begin_editing'
      weak_text_field=WeakRef.new(field)
      @events[:begin_edit].call(@model, @field_name, {text_field: weak_text_field}) unless @events[:begin_edit].nil?

    end

    def onPrepareForRelease
      @model=nil
      if !@ui_field.nil? && @ui_field.delegate == self
        @ui_field.delegate = nil
        toolbar = @ui_field.inputAccessoryView
        toolbar.items = nil unless toolbar.nil?
        @ui_field.inputAccessoryView = nil
      end
      @ui_field=nil
      @events=nil
    end

    def dealloc
      prepareForRelease
      ap 'dealloc ui_text_view input_binding'
      super
    end
  end
end