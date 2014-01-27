module Tgios
  class UIPickerViewListBinding < BindingBase
    def initialize
      @events={}
    end

    def on(event_name, &block)
      @events[event_name]=block
    end

    def bind(picker_view, list: list, display_field: display_field)
      @picker_view=WeakRef.new(picker_view)
      @list=WeakRef.new(list)
      @display_field=display_field
      @picker_view.dataSource=self
      @picker_view.delegate=self
    end


    def numberOfComponentsInPickerView(pickerView)
      1
    end

    def pickerView(picker_view, numberOfRowsInComponent:section)
      @list.length
    end

    def pickerView(pickerView, titleForRow: row, forComponent: component)
      @list[row][@display_field]
    end

    def pickerView(pickerView, didSelectRow:row, inComponent:component)
      @events[:row_selected].call(row, selected_record) unless @events[:row_selected].nil?
    end

    def selected_record
      @list[@picker_view.selectedRowInComponent(0)]
    end

    def select_record(record)
      idx = (@list.find_index(record) || 0)
      @picker_view.selectRow(idx, inComponent:0, animated: false)
    end

    def onPrepareForRelease
      @events=nil
      @picker_view.dataSource=nil
      @picker_view.delegate=nil
      @list=nil
    end

  end
end