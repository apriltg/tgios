module Tgios
  class SearchController < ExtendedUIViewController
    include ExtendedUITableView
    Events=[:record_selected, :search, :after_layout, :load_more]
    attr_accessor :table_list_binding_options, :pop_after_selected, :hide_keyboard, :field_name

    def on(event_name, &block)
      raise ArgumentError.new("Event not found, valid events are: [#{Events.join(', ')}]") unless Events.include?(event_name)
      @events[event_name]=block
      self
    end

    def result=(value)
      @result=value
      @search_result_table_binding.reload(@result) unless @search_result_table_binding.nil?
    end

    def select_record(record)
      @events[:record_selected].call(record)
      self.navigationController.popViewControllerAnimated(true) if @pop_after_selected
    end

    def viewDidLoad
      super
      @search_result_table = add_full_table_view_to(self.view, :plain)
      @search_result_table_binding=UITableViewListBinding.new.bind(@search_result_table, @result, @field_name, @table_list_binding_options)
      @search_result_table_binding.on(:touch_row) do |record, event|
        select_record(record)
      end.on(:load_more) do |page, index_path, &block|
        @events[:load_more].call(@search_bar.text, page, index_path, &block) unless @events[:load_more].nil?
      end

      @search_bar=UISearchBar.alloc.init
      @search_bar.frame=[[0,0],['100',0]]
      @search_bar.sizeToFit
      @search_bar.delegate=self
      @search_result_table.tableHeaderView=@search_bar
      @search_bar.becomeFirstResponder unless @hide_keyboard
      @events[:after_layout].call(@search_bar, @search_result_table) unless @events[:after_layout].nil?

    end

    def searchBarSearchButtonClicked(searchBar)
      searchBar.resignFirstResponder

      unless @events.nil? || @events[:search].nil?
        @events[:search].call(searchBar.text) do |success, result|
          if success
            @result=result
            if @result.count == 1
              select_record(@result.first)
            else
              @search_result_table_binding.reload(@result) unless @search_result_table_binding.nil?
            end
          end
        end
      end
    end

    def init
      super
      @events={}
      @result=[]
      @pop_after_selected=true
      self
    end

    def onPrepareForRelease
      @events=nil
      @search_result_table_binding.prepareForRelease
      @search_result_table_binding=nil
      self.navigationItem.rightBarButtonItem = nil
    end


  end
end