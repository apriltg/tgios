module Tgios
  class ImagesCollectionViewBinding < UICollectionViewBinding
    include PlasticCup
    attr_accessor :image_collection_view, :image_views
    def initialize(list, collection_view=nil, image_view_options={})
      super
      @image_collection_view = collection_view.nil? ? self.class.new_horizontal_collection_view : WeakRef.new(collection_view)
      @image_views = self.class.new_image_views(list, image_view_options)

      bind(@image_collection_view, @image_views)
    end

    def self.new_image_views(list, options={})
      image_views = []
      list.each do |item|
        image_view = Base.style(UIImageView.new, {frame: [[0,0], [50, 50]],
                                                  contentMode: UIViewContentModeScaleAspectFill,
                                                  layer: {
                                                      borderWidth: 1,
                                                      borderColor: :gray.uicolor.CGColor
                                                  },
                                                  clipsToBounds: true}.merge(options))
        CommonUIUtility.get_image(item) do |image|
          image_view.image = image
        end
        image_views << image_view
      end
      image_views
    end

    def list=(new_list)
      if new_list.is_a?(Array)
        @image_views = self.class.new_image_views(new_list)
        reload(@image_views)
      end
    end

    def onPrepareForRelease
      @image_collection_view = nil
      @image_views = nil
    end

  end
end