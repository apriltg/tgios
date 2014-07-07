module Tgios
  class ImageLoader < BindingBase

    def initialize(url)
      super
      @url = url
      @events = {}
    end

    def on(event, &block)
      @events[event]=block.weak!
    end

    def load
      image = get_image
      if image.nil?
        AFMotion::Image.get(@url) do |result|
          image = result.object
          image = self.class.scale_to(image, self.class.screen_scale)
          @events[:image_loaded].call(image, result.success?) unless @events.nil? || @events[:image_loaded].nil?
          save_image(image) if image.is_a?(UIImage)
        end
      else
        @events[:image_loaded].call(image, true) unless @events.nil? || @events[:image_loaded].nil?
      end
    end

    def get_image
      data = NSData.dataWithContentsOfFile(file_path)
      data.uiimage(self.class.screen_scale) unless data.nil?
    end

    def save_image(image)

      NSFileManager.defaultManager.createFileAtPath(self.file_path, contents: UIImageJPEGRepresentation(image, 0.95), attributes:nil)
    end

    def self.base_path
      @base_path ||= "#{NSTemporaryDirectory()}web/"
    end

    def filename
      @filename ||= (
      nsurl = NSURL.URLWithString(@url)
      path = "#{nsurl.host}#{nsurl.path}"
      CGI.escape(path)
      )
    end

    def file_path
      @file_path ||= (
      NSFileManager.defaultManager.createDirectoryAtPath(self.class.base_path,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil,
                                                         error: nil)
      "#{self.class.base_path}#{self.filename}"
      )
    end

    def self.clear_files
      fm = NSFileManager.defaultManager
      files = fm.contentsOfDirectoryAtPath(self.base_path, error:nil)
      files.each do |filename|
        fm.removeItemAtPath("#{self.base_path}#{filename}", error: nil)
      end if files.present?
      cache_path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).last
      fm.contentsOfDirectoryAtPath(cache_path, error: nil).each do |filename|
        fm.removeItemAtPath("#{cache_path}/#{filename}", error: nil)
      end
    end

    def self.load_url(url, &block)
      if url.nil?
        block.call(nil, nil)
      else
        image_loader = ImageLoader.new(url)
        image_loader.on(:image_loaded) do |image, success|
          block.call(image, success)
          image_loader.prepareForRelease
        end
        image_loader.load
      end
    end

    def self.scale_to(image, scale=screen_scale)
      if image.is_a?(UIImage) && image.scale != scale
        UIImage.imageWithCGImage(image.CGImage, scale: scale, orientation: image.imageOrientation)
      else
        image
      end
    end

    def self.screen_scale
      UIScreen.mainScreen.scale
    end


    def onPrepareForRelease
      @events = nil
    end
  end
end