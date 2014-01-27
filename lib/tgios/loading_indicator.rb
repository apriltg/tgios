include PlasticCup
module Tgios
  module LoadingIndicator
    def add_loading_indicator_to(view)
      Base.add_style_sheet(:loading_view, {
          backgroundColor: :black.uicolor,
          alpha: 0.5
      })
      @loading_view = Base.style(UIView.new, hidden: true)
      base_view = Base.style(UIView.new, :loading_view)
      @indicator = UIActivityIndicatorView.large
      [{super_view: view, subview: @loading_view}, {super_view: @loading_view, subview: base_view}, {super_view: @loading_view, subview: @indicator}].each do |hash|
        Motion::Layout.new do |l|
          l.view hash[:super_view]
          l.subviews 'subview' => hash[:subview]
          l.vertical '|[subview]|'
          l.horizontal '|[subview]|'
        end
      end
      @label = Base.style(UILabel.new,
                          frame: view.bounds,
                          font: lambda {UIFont.systemFontOfSize(22)},
                          textAlignment: :center.uialignment,
                          backgroundColor: :clear.uicolor,
                          textColor: :white.uicolor)
      @label.sizeToFit
      Motion::Layout.new do |l|
        l.view @loading_view
        l.subviews 'label' => @label
        l.vertical '[label]-290-|'
        l.horizontal '|-20-[label]-20-|'
      end
    end

    def start_loading(text='')
      @label.text = text
      self.view.endEditing(true)
      @loading_view.hidden = false
      @indicator.startAnimating
    end

    def stop_loading
      @loading_view.hidden = true
      @indicator.stopAnimating
    end
  end
end