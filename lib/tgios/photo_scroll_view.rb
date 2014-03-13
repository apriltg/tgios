module Tgios
  class PhotoScrollView < UIScrollView
    attr_accessor :image
    MAX_SCALE = 4.0

    def init
      if super
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.delegate = self
        self.backgroundColor = :clear.uicolor
      end
      self
    end

    def initWithFrame(frame, image: image)
      init
      self.frame = frame
      self.image = image

      self
    end

    def image=(image)
      super
      if image.is_a?(UIImage)
        frame = self.frame
        page_rect = CGRectMake(0, 0, image.size.width, image.size.height)

        img_scale = frame.size.width / page_rect.size.width
        fit_scale = frame.size.height / page_rect.size.height
        fit_scale = img_scale if img_scale < fit_scale

        page_rect.size = CGSizeMake(page_rect.size.width * img_scale, page_rect.size.height * img_scale)

        @image_view = PlasticCup::Base.style(UIImageView.new,
                                             image: image,
                                             frame: page_rect,
                                             contentMode: UIViewContentModeScaleAspectFit)
        self.addSubview(@image_view)

        self.zoomScale = 0.995 if page_rect.size.height > frame.size.height

        self.maximumZoomScale = MAX_SCALE / img_scale
        self.minimumZoomScale = fit_scale / img_scale
      end
    end

    def layoutSubviews
      super
      unless @image_view.nil?
        bsize = self.bounds.size
        center_frame = @image_view.frame

        center_frame.origin.x = center_frame.size.width < bsize.width ? (bsize.width - center_frame.size.width) / 2.0 : 0
        center_frame.origin.y = center_frame.size.height < bsize.height ? (bsize.height - center_frame.size.height) / 2.0 : 0

        @image_view.frame = center_frame
        @image_view.contentScaleFactor = 1.0

      end

    end

    def viewForZoomingInScrollView(scrollView)
      @image_view
    end

    def dealloc
      ap "dealloc #{self.class.name}"
      super
    end

  end
end