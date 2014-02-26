include PlasticCup
module Tgios
  class LoadingView < UIView
    def initWithFrame(frame)
      if super
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

    def start_loading(text='')
      @label.text = text
      self.hidden = false
      @indicator.startAnimating
    end

    def stop_loading
      self.hidden = true
      @indicator.stopAnimating
    end
  end

  module LoadingIndicator
    def add_loading_indicator_to(view)
      @loading_view = LoadingView.add_loading_view_to(view)
    end

    def start_loading(text='')
      self.view.endEditing(true)
      @loading_view.start_loading(text)
    end

    def stop_loading
      @loading_view.stop_loading
    end
  end
end