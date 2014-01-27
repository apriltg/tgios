module Tgios
  class PhotoScrollView < UIScrollView
    MAX_SCALE = 4.0

    def initWithFrame(frame, image: image)
      initWithFrame(frame)
      ap "init #{self.class.name}"
      self.showsVerticalScrollIndicator = false
      self.showsHorizontalScrollIndicator = false
      self.bouncesZoom = true
      self.decelerationRate = UIScrollViewDecelerationRateFast
      self.delegate = self
      self.backgroundColor = :clear.uicolor

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

      self
    end

    def layoutSubviews
      super

      bsize = self.bounds.size
      center_frame = @image_view.frame

      center_frame.origin.x = center_frame.size.width < bsize.width ? (bsize.width - center_frame.size.width) / 2.0 : 0
      center_frame.origin.y = center_frame.size.height < bsize.height ? (bsize.height - center_frame.size.height) / 2.0 : 0

      @image_view.frame = center_frame
      @image_view.contentScaleFactor = 1.0

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