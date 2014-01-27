module Tgios
  class PhotoController < ExtendedUIViewController
    include LoadingIndicator
    attr_accessor :url

    def viewDidLoad
      super
      self.view.backgroundColor = :black.uicolor

      add_loading_indicator_to(self.view)
      unless @url.nil?
        start_loading
        image_loader = ImageLoader.new(@url)
        image_loader.on(:image_loaded) do |image, success|
          stop_loading
          if success
            ap 'image loaded'
            # TODO: use motion layout or other way to handle frame size (or allow full screen)
            small_frame = self.view.bounds
            small_frame.size.height -= 20 + 44 if small_frame == UIScreen.mainScreen.bounds

            scroll_view = PhotoScrollView.alloc.initWithFrame(small_frame, image: image)
            self.view.addSubview(scroll_view)
          end
          image_loader.prepareForRelease
        end
        image_loader.load

      end
    end

    def onPrepareForRelease
    end
  end
end