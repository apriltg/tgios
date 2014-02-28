module Tgios
  class ImageLoader < BindingBase

    def initialize(url)
      super
      @url = url
      @events = {}
    end

    def on(event, &block)
      @events[event]=block
    end

    def load
      image = get_image
      if image.nil?
        AFMotion::Image.get(@url) do |result|
          image = result.object
          @events[:image_loaded].call(image, result.success?) unless @events.nil? || @events[:image_loaded].nil?
          save_image(image)
        end
      else
        @events[:image_loaded].call(image, true) unless @events.nil? || @events[:image_loaded].nil?
      end
    end

    def get_image
      UIImage.imageWithContentsOfFile(file_path)
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
      fm.contentsOfDirectoryAtPath(self.base_path, error:nil).each do |filename|
        fm.removeItemAtPath("#{self.base_path}#{filename}", error: nil)
      end
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

    def onPrepareForRelease
      @events = nil
    end
  end
end