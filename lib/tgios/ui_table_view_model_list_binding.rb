module Tgios
  class UITableViewModelListBinding < BindingBase
    def initialize
      super

      @events={}
      @events[:build_cell]=->(cell_identifier, type) { build_cell(cell_identifier, type)}
      @events[:update_cell]=->(field_set, cell, index_path) { update_field(field_set, cell, index_path)}
      @events[:update_cell_height]=->(field_set, index_path) { update_cell_height(field_set, index_path) }
      self

    end

    def bind(tableView, models, fields)
      @tableView=WeakRef.new(tableView)
      @fields=fields
      @contact_buttons = []
      @models=WeakRef.new(models)
      @tableView.dataSource=self
      @tableView.delegate=self
      self
    end

    def models=(value)
      @models=value
      @tableView.reloadData
    end

    def on(event_name, &block)
      @events[event_name]=block.weak!
      self
    end


    def tableView(tableView, cellForRowAtIndexPath: index_path)

      field_set = field_set_at_index_path(index_path)
      type = field_set[:child_index].nil? ? field_set[:type] : field_set[:child_field][:type]

      cell_identifier = "CELL_IDENTIFIER_#{type}"
      cell=tableView.dequeueReusableCellWithIdentifier(cell_identifier)
      isReusedCell=!cell.nil?

      cell=@events[:build_cell].call(cell_identifier, type) unless isReusedCell

      @events[:update_cell].call(field_set, cell, index_path)

      cell

    end

    def build_cell(cell_identifier, type)
      cell = UITableViewCell.value1(cell_identifier)
      cell.detailTextLabel.adjustsFontSizeToFitWidth = true
      cell.clipsToBounds = true
      cell
    end

    def update_field(o_field_set, cell, index_path)
      model = @models[index_path.section]
      field_set = o_field_set
      if !field_set[:child_index].nil?
        model = model.send(field_set[:name])[field_set[:child_index]]
        field_set = field_set[:child_field]
      end

      accessory_view = cell.accessoryView
      if field_set[:accessory] == :contact
        if accessory_view && accessory_view.buttonType == :contact.uibuttontype
          contact_button = accessory_view
        else
          contact_button = (@contact_buttons.pop || UIButton.contact)
          cell.accessoryView = contact_button
        end
        unhook(contact_button, :tapped)
        hook(contact_button, :tapped) do
          tableView(@tableView, didSelectRowAtIndexPath:index_path)
        end
      else
        if accessory_view && accessory_view.buttonType == :contact.uibuttontype
          @contact_buttons << accessory_view
          cell.accessoryView = nil
        end
        cell.accessoryType = (field_set[:accessory] || :none).uitablecellaccessory
      end

      case field_set[:type]
        when :array
          cell.textLabel.text=field_set[:label]
          cell.detailTextLabel.text = ''
        when :label, :text
          cell.textLabel.text= field_set[:show_label] ? field_set[:label] : field_set[:label_name].nil? ? '' : model.send(field_set[:label_name])
          cell.detailTextLabel.text = model.send(field_set[:name])
        when :big_label
          cell.detailTextLabel.numberOfLines = 0
          cell.detailTextLabel.backgroundColor = :clear.uicolor
          cell.detailTextLabel.text = model.send(field_set[:name])
      end

    end

    def tableView(tableView, didSelectRowAtIndexPath:index_path)
      @selected_field_set=field_set_at_index_path(index_path)
      @events[:touch_row].call(@selected_field_set, {tableView: tableView, didSelectRowAtIndexPath:index_path}) if @events.has_key?(:touch_row)

    end

    def tableView(tableView, numberOfRowsInSection: section)
      count = @fields.length
      @fields.each do |fld|
        count += @models[section].send(fld[:name]).length if fld[:type] == :array
      end
      count
    end

    def numberOfSectionsInTableView(tableView)
      @models.length
    end

    def tableView(tableView, commitEditingStyle:editingStyle, forRowAtIndexPath:index_path)
      if editingStyle == UITableViewCellEditingStyleDelete
        field_set = field_set_at_index_path(index_path)
        real_fs = field_set
        real_fs = real_fs[:child_field] unless real_fs[:child_index].nil?
        if real_fs[:delete] == true # TODO: change :delete to :delete_row after trim-ios changed
          unless @events[:delete_row].nil?
            @events[:delete_row].call(field_set, @models[index_path.section].send(field_set[:name]), {tableView: tableView, commitEditingStyle: editingStyle, forRowAtIndexPath:index_path}) do |success|
              tableView.deleteRowsAtIndexPaths([index_path], withRowAnimation: UITableViewRowAnimationFade) if success
            end
          end
        elsif real_fs[:delete_section] == true
          unless @events[:delete_section].nil?
            @events[:delete_section].call(field_set, @models[index_path.section], {tableView: tableView, commitEditingStyle:editingStyle, forRowAtIndexPath:index_path}) do |success|
              tableView.deleteSections(NSIndexSet.indexSetWithIndex(index_path.section), withRowAnimation: UITableViewRowAnimationFade) if success
            end
          end
        end
      end
    end

    def tableView(tableView, canEditRowAtIndexPath: index_path)
      field_set = field_set_at_index_path(index_path)
      can_edit = @events[:can_edit].call(field_set, index_path) unless @events[:can_edit].nil?
      if can_edit.nil?
        field_set = field_set[:child_field] unless field_set[:child_index].nil?
        can_edit = field_set[:delete] == true || field_set[:delete_section] == true
      end
      can_edit
    end

    def tableView(tableView, heightForRowAtIndexPath: index_path)
      field_set = field_set_at_index_path(index_path)
      @events[:update_cell_height].call(field_set, index_path)
    end

    def update_cell_height(field_set, index_path)
      field_set = field_set[:child_field] unless field_set[:child_index].nil?
      return field_set[:height] unless field_set[:height].nil?
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

    def tableView(tableView, willDisplayCell:cell, forRowAtIndexPath:indexPath)
      unless @events[:reach_bottom].nil? || indexPath.section < @models.length - 1 || indexPath.row < tableView(nil, numberOfRowsInSection: indexPath.section) - 1
        @events[:reach_bottom].call(indexPath)
      end
    end

    def field_set_at_index_path(index_path)
      row = index_path.row
      array_indices = @fields.each_index.select{|i| @fields[i][:type] == :array}
      return @fields[row] if array_indices.empty? || array_indices.first >= row
      array_count_sum = 0
      array_indices.each do |a_idx|
        array_count = @models[index_path.section].send(@fields[a_idx][:name]).length
        if row <= a_idx + array_count_sum + array_count
          sub_idx = row - a_idx - array_count_sum - 1
          return sub_idx < 0 ? @fields[a_idx + sub_idx + 1] : @fields[a_idx].merge(child_index: sub_idx)
        end
        array_count_sum += array_count
      end
      @fields[row - array_count_sum]
    end

    def onPrepareForRelease
      @contact_buttons = nil
      @events=nil
      @models=nil
      @tableView.delegate=nil
      @tableView.dataSource=nil
      @tableView=nil

    end
  end
end