module Tgios
  class UITableViewListBinding < BindingBase
    def initialize
      @events={}
      @events[:build_cell]=->(cell_identifier) { build_cell(cell_identifier) }
      @events[:update_cell]=->(record, cell, index_path) { update_cell_text(record, cell, index_path)}
    end

    def bind(tableView, list, display_field, options={})
      @tableView=WeakRef.new(tableView)
      @tableView.dataSource=self
      @tableView.delegate=self
      @display_field=display_field
      @list=WeakRef.new(list)
      @options=(options || {})
      return self
    end

    def on(event_name, &block)
      @events[event_name]=block
      self
    end

    def reload(list)
      @list=list
      @tableView.reloadData()
    end

    def build_cell(cell_identifier)
      cell=UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: cell_identifier)
      cell.textLabel.adjustsFontSizeToFitWidth = true
      if @options[:lines] && @options[:lines] != 1
        cell.textLabel.numberOfLines = 0
      end
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
      if @options[:lines]
        20 + 20 * (@options[:lines] || 2)
      else
        45
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