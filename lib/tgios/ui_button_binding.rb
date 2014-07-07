module Tgios
  class UIButtonBinding < BindingBase
    def initialize
      @events={}
    end

    def on(event_name, &block)
      @events[event_name]= block.weak!
      self
    end

    def bind(button)
      @button=WeakRef.new(button)
      @button.addTarget(self, action: 'button_tapped', forControlEvents: UIControlEventTouchUpInside)
      self
    end

    def button_tapped
      ap "button_tapped"
      @events[:tapped].call unless @events[:tapped].nil?
    end

    def onPrepareForRelease
      @events=nil
    end

    def self.unbind(button)
      button.removeTarget(nil, action: 'button_tapped', forControlEvents: UIControlEventTouchUpInside)
    end

    def dealloc
      @button.removeTarget(self, action: 'button_tapped', forControlEvents: UIControlEventTouchUpInside) if @button.weakref_alive?
      super
    end
  end
end