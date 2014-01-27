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
      image = UIImage.imageWithContentsOfFile(self.file_path)
      if image.nil?
        AFMotion::HTTP.get(@url) do |result|
          image = UIImage.imageWithData(result.object)
          @events[:image_loaded].call(image, result.success?) unless @events.nil? || @events[:image_loaded].nil?
          NSFileManager.defaultManager.createFileAtPath(self.file_path, contents: result.object, attributes:nil)
        end
      else
        @events[:image_loaded].call(image, true) unless @events.nil? || @events[:image_loaded].nil?
      end
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
    end

    def onPrepareForRelease
      @events = nil
    end
  end
end