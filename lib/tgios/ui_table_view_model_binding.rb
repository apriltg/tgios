module Tgios
  class UITableViewModelBinding < BindingBase

    def initialize
      super
      PlasticCup::Base.add_style_sheet(:ui_field_default_styles, {
          clearButtonMode: UITextFieldViewModeWhileEditing,
          tag: 99
      }) unless Base.get_style_sheet(:ui_field_default_styles)
      PlasticCup::Base.add_style_sheet(:ui_field_without_label, {
          extends: :ui_field_default_styles,
          frame: CGRectMake(16, 9, 292, 25)
      }, :ios7) unless Base.get_style_sheet(:ui_field_without_label)
      PlasticCup::Base.add_style_sheet(:ui_field_without_label, {
          extends: :ui_field_default_styles,
          frame: CGRectMake(16, 9, 282, 25)
      }) unless Base.get_style_sheet(:ui_field_without_label)
      PlasticCup::Base.add_style_sheet(:ui_field_with_label, {
          extends: :ui_field_default_styles,
          frame: CGRectMake(114, 9, 194, 25)
      }, :ios7) unless Base.get_style_sheet(:ui_field_with_label)
      PlasticCup::Base.add_style_sheet(:ui_field_with_label, {
          extends: :ui_field_default_styles,
          frame: CGRectMake(84, 9, 214, 25)
      }) unless Base.get_style_sheet(:ui_field_with_label)
      PlasticCup::Base.add_style_sheet(:ui_view_default_styles, {
          font: lambda {UIFont.systemFontOfSize(15)},
          backgroundColor: :clear.uicolor,
          tag: 88
      }) unless Base.get_style_sheet(:ui_view_default_styles)

      @events={}
      @events[:build_cell]=->(cell_identifier, type) { build_cell(cell_identifier, type) }
      @events[:update_cell]=->(field_set, cell, index_path) { create_or_update_field(field_set, cell, index_path)}
      @events[:update_accessory]=->(field_set, cell, index_path, ui_field) { update_accessory_type_or_view(field_set, cell, index_path, ui_field)}
      @events[:update_cell_height]=->(field_set, index_path) { update_cell_height(field_set, index_path) }
    end



    def bind(tableView, model, fields)
      @tableView=WeakRef.new(tableView)
      @fields=fields
      bindings_prepare_release
      @bindings={}
      @tv_bindings={}
      self.model=model
      @tableView.dataSource=self
      @tableView.delegate=self
      self
    end

    def model=(value)
      @model=WeakRef.new(value)
      @tableView.reloadData()
    end

    def reload
      @tableView.reloadData
    end

    def on(event_name, &block)
      @events[event_name]=block
      self
    end

    def tableView(tableView, cellForRowAtIndexPath: index_path)
      field_set = field_set_at_index_path(index_path)
      type = field_set[:child_index].nil? ? field_set[:type] : field_set[:child_field][:type]
      cell_identifier = "CELL_IDENTIFIER_#{type.to_s}"
      cell=tableView.dequeueReusableCellWithIdentifier(cell_identifier)
      isReusedCell=!cell.nil?

      cell=@events[:build_cell].call(cell_identifier, type) unless isReusedCell
      weak_cell=WeakRef.new(cell)

      ui_field=@events[:update_cell].call(field_set, weak_cell, index_path) unless @events[:update_cell].nil?
      @events[:update_accessory].call(field_set, weak_cell, index_path, ui_field) unless @events[:update_accessory].nil?
      cell

    end

    def build_cell(cell_identifier, type)
      if type == :checkbox
        cell = UITableViewCell.default(cell_identifier)
        cell.textLabel.numberOfLines = 0
      elsif type == :dynamic_label || type == :big_label
        cell = UITableViewCell.value2(cell_identifier)
        cell.detailTextLabel.numberOfLines = 0
        cell.detailTextLabel.backgroundColor = :clear.uicolor
        cell.textLabel.numberOfLines = 0
      else
        cell = UITableViewCell.value2(cell_identifier)
        cell.textLabel.numberOfLines = 2
      end
      cell
    end

    def create_or_update_field(field_set, cell, index_path)
      ui_field=nil
      #ap field_set
      cell.textLabel.text= field_set[:show_label] ? field_set[:label] : ''

      cell.selectionStyle=UITableViewCellSelectionStyleNone
      case field_set[:type]
        when :text, :password, :label
          ui_field=cell.contentView.viewWithTag(99)

          if ui_field.nil?
            ui_field = UITextField.new
            cell.contentView.addSubview(ui_field)
          end

          if field_set[:show_label]
            PlasticCup::Base.style(ui_field, :ui_field_with_label)
          else
            PlasticCup::Base.style(ui_field, :ui_field_without_label)
          end
          ui_field.placeholder= field_set[:show_label] ? field_set[:placeholder] : field_set[:label]

          text_field_binding=@bindings[field_set[:name]]
          if text_field_binding.nil?
            text_field_binding=UITextFieldBinding.new(@model, ui_field, field_set[:name], field_set)
            text_field_binding.on(:begin_edit) do |model, field_name, event|
              @events[:text_begin_edit].call(model, field_name, event) unless @events[:text_begin_edit].nil?
              performSelector('will_scroll_to_index_path:', withObject: index_path, afterDelay:0.01)
            end
            text_field_binding.on(:return_tapped) do |model, field_name, event|
              @events[:text_return_tapped].call(model, field_name, event) unless @events[:text_return_tapped].nil?
            end
            @bindings[field_set[:name]]=text_field_binding
          end
          text_field_binding.update(ui_field, @model)
          ui_field.becomeFirstResponder if field_set[:first_responder] # TODO: not work when cell is not visible, buggy
        when :big_label, :dynamic_label
          cell.detailTextLabel.text = @model.send(field_set[:name])

        when :array
          if field_set[:child_index].nil?
            cell.detailTextLabel.text = field_set[:label]
          else
            child_field = field_set[:child_field]
            child = @model.send(field_set[:name])[field_set[:child_index]]
            if child_field[:type] == :checkbox
              cell.textLabel.text = child[child_field[:display_field]]
              cell.imageView.image = child[:selected] ? 'tick_select.png'.uiimage : 'tick_deselect.png'.uiimage
            else
              cell.textLabel.text = nil
              cell.detailTextLabel.numberOfLines = 0
              cell.detailTextLabel.text = child[child_field[:display_field]]
            end
          end

        when :checkbox
          cell.textLabel.text = field_set[:label]
          cell.imageView.image = @model.send(field_set[:name])== true ? 'tick_select.png'.uiimage : 'tick_deselect.png'.uiimage

        when :label_only
          cell.detailTextLabel.text = field_set[:label]

        when :text_view

          ui_field=cell.contentView.viewWithTag(88)
          ui_field_default_frame = Rect([[16, 9], [282, 90]])

          if ui_field.nil?
            ui_field = PlasticCup::Base.style(UITextView.new, :ui_view_default_styles)
            cell.contentView.addSubview(ui_field)
          end

          ui_field.frame = ui_field_default_frame

          text_field_binding=@tv_bindings[field_set[:name]]
          if text_field_binding.nil?
            text_field_binding=UITextViewBinding.new(@model, ui_field, field_set[:name], field_set)
            text_field_binding.on(:begin_edit) do |model, field_name, event|
              @events[:text_begin_edit].call(model, field_name, event) unless @events[:text_begin_edit].nil?
              performSelector('will_scroll_to_index_path:', withObject: index_path, afterDelay:0.01)
            end
            text_field_binding.on(:return_tapped) do |model, field_name, event|
              @events[:text_return_tapped].call(model, field_name, event) unless @events[:text_return_tapped].nil?
            end
            @tv_bindings[field_set[:name]]=text_field_binding
          end
          text_field_binding.update(ui_field, @model)
          ui_field.becomeFirstResponder if field_set[:first_responder] # TODO: not work when cell is not visible, buggy



      end

      ui_field
    end

    def update_accessory_type_or_view(field_set, cell, index_path, ui_field)
      cell.accessoryType = (field_set[:accessory] || :none).uitablecellaccessory
      cell.accessoryView = nil
    end

    def tableView(tableView, didSelectRowAtIndexPath:index_path)
      @selected_field_set=field_set_at_index_path(index_path)
      @events[:touch_row].call(@selected_field_set, {tableView: tableView, didSelectRowAtIndexPath:index_path}) if @events.has_key?(:touch_row)
      if @selected_field_set[:scroll]
        performSelector('will_scroll_to_index_path:', withObject: index_path, afterDelay:0.01)
      end

      field_set = @selected_field_set
      unless field_set[:child_index].nil?
        field_set = field_set[:child_field]
        if field_set[:type] == :checkbox
          child = @model.send(@selected_field_set[:name])[@selected_field_set[:child_index]]
          child[:selected] = !(child[:selected] || false)
          reload
        end
      end
    end

    def tableView(tableView, numberOfRowsInSection: section)
      count = @fields.length
      @fields.each do |fld|
        count += @model.send(fld[:name]).length if fld[:type] == :array
      end
      count
    end

    def tableView(tableView, heightForRowAtIndexPath: index_path)
      field_set = field_set_at_index_path(index_path)
      field_set = field_set[:child_field] unless field_set[:child_index].nil?
      @events[:update_cell_height].call(field_set, index_path)
    end

    def update_cell_height(field_set, index_path)
      if field_set[:type] == :big_label || field_set[:type] == :checkbox
        26 + 19 * (field_set[:lines] || 2)
      elsif field_set[:type] == :text_view
        110
      elsif field_set[:type] == :dynamic_label
        return 45 if @model.send(field_set[:name]).nil?
        width = 284
        width -= 20 unless field_set[:accessory].nil? || field_set[:accessory] == :none
        width -= 94 if field_set[:show_label]
        height = @model.send(field_set[:name]).sizeWithFont(UIFont.systemFontOfSize(14),
                                                            constrainedToSize: [width, 9999],
                                                            lineBreakMode: UILineBreakModeCharacterWrap).height + 20
        [height, 45].max
      else
        45
      end
    end

    def field_set_at_index_path(index_path)
      row = index_path.row
      array_indices = @fields.each_index.select{|i| @fields[i][:type] == :array}
      return @fields[row] if array_indices.empty? || array_indices.first >= row
      array_count_sum = 0
      array_indices.each do |a_idx|
        array_count = @model.send(@fields[a_idx][:name]).length
        if row <= a_idx + array_count_sum + array_count
          sub_idx = row - a_idx - array_count_sum - 1
          return sub_idx < 0 ? @fields[a_idx + sub_idx + 1] : @fields[a_idx].merge(child_index: sub_idx)
        end
        array_count_sum += array_count
      end
      @fields[row - array_count_sum]
    end

    def listen_to_keyboard
      @scroll_when_editing = true
      NSNotificationCenter.defaultCenter.addObserver(self, selector: 'keyboardWillShow:', name: UIKeyboardWillShowNotification, object: nil)
      NSNotificationCenter.defaultCenter.addObserver(self, selector: 'keyboardWillHide:', name: UIKeyboardWillHideNotification, object: nil)
    end

    def stop_listen_to_keyboard
      @scroll_when_editing = false
      NSNotificationCenter.defaultCenter.removeObserver(self)
    end

    def keyboardWillShow(note)
      shrink_table_view(note)
    end

    def keyboardWillHide(note)
      expand_table_view(note)
    end

    def expand_table_view(note)
      @expanding = true
      offset_y = @tableView.contentOffset.y
      frame_height = @tableView.frame.size.height
      content_height = @tableView.contentSize.height
      new_offset_height = nil
      if frame_height > content_height
        if offset_y != 0
          new_offset_height = 0
        end
      else
        bottom_offset = frame_height - content_height + offset_y
        if bottom_offset > 0
          new_offset_height = offset_y - bottom_offset
        end
      end

      if new_offset_height.nil?
        reset_content_inset_bottom
      else
        curve = note[UIKeyboardAnimationCurveUserInfoKey]
        duration = note[UIKeyboardAnimationDurationUserInfoKey]
        @animation_proc = -> {
          @tableView.setContentOffset([0, new_offset_height])
        }
        @completion_proc = lambda { |finished|
          reset_content_inset_bottom
        }
        UIView.animateWithDuration(duration-0.01, delay: 0, options: curve,
                                   animations: @animation_proc,
                                   completion: @completion_proc)
      end
    end

    def shrink_table_view(note)
      # TODO: don't shrink when table frame bottom is above the keyboard
      @shrinking = true
      rect = note[UIKeyboardFrameEndUserInfoKey].CGRectValue
      if @expanding
        @shrink_height = rect.size.height
      else
        set_content_inset_bottom(rect.size.height)
      end
    end

    def reset_content_inset_bottom
      @tableView.contentInset = UIEdgeInsetsZero
      @tableView.scrollIndicatorInsets = UIEdgeInsetsZero
      @expanding = false
      if @shrink_height
        set_content_inset_bottom(@shrink_height)
        @shrink_height = nil
      end
    end

    def set_content_inset_bottom(height)
      @tableView.contentInset = UIEdgeInsetsMake(0,0,height,0)
      @tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0,0,height,0)
      @shrinking = false
      if @index_path_to_scroll
        scroll_to_index_path(@index_path_to_scroll)
        @index_path_to_scroll = nil
      end
    end

    def will_scroll_to_index_path(index_path)
      if @scroll_when_editing
        if @shrinking
          @index_path_to_scroll = index_path
        else
          scroll_to_index_path(index_path)
        end
      end
    end

    def scroll_to_index_path(index_path)
      @tableView.scrollToRowAtIndexPath(index_path, atScrollPosition: UITableViewScrollPositionBottom, animated: true)
      @index_path_to_scroll = nil
    end

    def bindings_prepare_release
      @bindings.values.each do |binding|
        binding.prepareForRelease
      end if @binding.is_a?(Hash)
      @tv_bindings.values.each do |binding|
        binding.prepareForRelease
      end if @tv_bindings.is_a?(Hash)
    end

    def onPrepareForRelease
      bindings_prepare_release
      self.stop_listen_to_keyboard
      @animation_proc=nil
      @completion_proc=nil
      @bindings=nil
      @tv_bindings=nil
      @events=nil
      @tableView.dataSource=nil
      @tableView.delegate=nil
      @tableView=nil
      @model=nil
    end

  end
end