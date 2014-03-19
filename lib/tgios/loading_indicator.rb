include PlasticCup
module Tgios
  class LoadingView < UIView
    attr_accessor :load_count

    def initWithFrame(frame)
      if super
        @load_count = 0
        self.hidden = true
        base_view = Base.style(UIView.new, backgroundColor: :black.uicolor, alpha: 0.5)

        @indicator = UIActivityIndicatorView.large
        [{super_view: self, subview: base_view}, {super_view: self, subview: @indicator}].each do |hash|
          CommonUIUtility.add_full_subview(hash[:super_view], hash[:subview])
        end
        @label = Base.style(UILabel.new,
                            frame: self.bounds,
                            font: lambda {UIFont.systemFontOfSize(22)},
                            textAlignment: :center.uialignment,
                            backgroundColor: :clear.uicolor,
                            textColor: :white.uicolor)
        @label.sizeToFit
        Motion::Layout.new do |l|
          l.view self
          l.subviews 'label' => @label
          l.vertical '[label]-290-|'
          l.horizontal '|-20-[label]-20-|'
        end
      end
      self
    end

    def self.add_loading_view_to(view)
      loading_view = LoadingView.alloc.initWithFrame(view.bounds)
      CommonUIUtility.add_full_subview(view, loading_view)
      loading_view
    end

    def start_loading(text='', force=false)
      @label.text = text
      if @load_count <= 0 || force
        self.hidden = false
        @indicator.startAnimating
      end
      @load_count += 1
    end

    def stop_loading(force=false)
      @load_count -=1
      if @load_count <= 0 || force
        self.hidden = true
        @indicator.stopAnimating
      end
    end
  end

  module LoadingIndicator
    def add_loading_indicator_to(view)
      @loading_view = LoadingView.add_loading_view_to(view)
    end

    def start_loading(text='', force=false)
      self.view.endEditing(true)
      @loading_view.start_loading(text, force)
    end

    def stop_loading(force=false)
      @loading_view.stop_loading(force)
    end
  end
end