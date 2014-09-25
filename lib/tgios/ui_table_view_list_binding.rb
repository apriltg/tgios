module Tgios
  class UITableViewListBinding < BindingBase
    def initialize
      @events={}
      @events[:build_cell]=->(cell_identifier) { build_cell(cell_identifier) }.weak!
      @events[:update_cell]=->(record, cell, index_path) { update_cell_text(record, cell, index_path)}.weak!
    end

    def bind(tableView, list, display_field, options={})
      @tableView=WeakRef.new(tableView)
      @tableView.dataSource=self
      @tableView.delegate=self
      @display_field=display_field
      set_list(list)
      @options=(options || {})
      return self
    end

    def on(event_name, &block)
      @events[event_name]=block.weak!
      self
    end

    def reload(list)
      set_list(list)
      @tableView.reloadData()
    end

    def set_list(list)
      @list=WeakRef.new(list)
      @page = 1
      @total = nil
    end

    def build_cell(cell_identifier)
      cell=UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: cell_identifier)
      cell.textLabel.adjustsFontSizeToFitWidth = true
      if @options[:lines] && @options[:lines] != 1
        cell.textLabel.numberOfLines = 0
      end
      cell.clipsToBounds = true
      cell
    end

    def update_cell_text(record, cell, index_path)
      cell.textLabel.text=record[@display_field]
      cell
    end

    def tableView(tableView, cellForRowAtIndexPath: index_path)
      record = @list[index_path.row]
      cell_identifier = "CELL_IDENTIFIER"
      cell=tableView.dequeueReusableCellWithIdentifier(cell_identifier)
      cell = @events[:build_cell].call(cell_identifier) if cell.nil?
      @events[:update_cell].call(record, cell, index_path)
      cell

    end

    def tableView(tableView, didSelectRowAtIndexPath:index_path)
      @events[:touch_row].call(@list[index_path.row], event: {tableView: tableView, didSelectRowAtIndexPath:index_path}) if @events.has_key?(:touch_row)
    end

    def tableView(tableView, numberOfRowsInSection: section)
      @list.length
    end

    def tableView(tableView, heightForRowAtIndexPath: index_path)
      height = if @events.has_key?(:cell_height)
                 record = @list[index_path.row]
                 @events[:cell_height].call(index_path, record)
               end
      return height if height.is_a?(Numeric)
      cell_height
    end

    def cell_height
      return @options[:height] unless @options[:height].nil?
      if @options[:lines]
        26 + 19 * (@options[:lines] || 2)
      else
        45
      end
    end

    def tableView(tableView, willDisplayCell:cell, forRowAtIndexPath:indexPath)
      unless @events[:load_more].nil? || indexPath.row < @list.length - 1 || !@total.nil? && @total <= @list.count || @loading
        @loading = true
        @events[:load_more].call(@page+1, indexPath) do |success, results, total|
          if success && !@list.nil?
            @total = total
            @page += 1
            @list += results
            @tableView.reloadData
          end
          @loading = false
        end
      end
    end

    def onPrepareForRelease
      @events=nil
      @list=nil
      @display_field=nil
      @tableView.delegate=nil
      @tableView.dataSource=nil
      @tableView=nil

    end



  end

end