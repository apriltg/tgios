module Tgios
  # common usage:
  # call listen_to_keyboard in viewWillAppear
  # call stop_listen_to_keyboard in viewWillDisappear
  # call will_scroll_to_index_path in text field begin_edit event
  class UITableViewUtilityBinding < BindingBase
    def bind(table)
      @table = WeakRef.new(table)
      self
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
      offset_y = @table.contentOffset.y
      frame_height = @table.frame.size.height
      content_height = @table.contentSize.height
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
          @table.setContentOffset([0, new_offset_height])
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
      @table.contentInset = UIEdgeInsetsZero
      @table.scrollIndicatorInsets = UIEdgeInsetsZero
      @expanding = false
      if @shrink_height
        set_content_inset_bottom(@shrink_height)
        @shrink_height = nil
      end
    end

    def set_content_inset_bottom(height)
      @table.contentInset = UIEdgeInsetsMake(0,0,height,0)
      @table.scrollIndicatorInsets = UIEdgeInsetsMake(0,0,height,0)
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
          performSelector('scroll_to_index_path:', withObject: index_path, afterDelay:0.01)
        end
      end
    end

    def scroll_to_index_path(index_path)
      @table.scrollToRowAtIndexPath(index_path, atScrollPosition: UITableViewScrollPositionBottom, animated: true)
      @index_path_to_scroll = nil
    end

    def onPrepareForRelease
      self.stop_listen_to_keyboard
      @animation_proc=nil
      @completion_proc=nil
      @table=nil
    end
  end
end