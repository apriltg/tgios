module Tgios
  class PhotoUpload < BindingBase

    def initialize
      @events = {}
    end

    def on(event_key,&block)
      @events[event_key] = block.weak!
    end

    def upload_s3(fixed_image, get_s3_result, s3_appended_hash=nil, s3_removed_key_arr=nil, &block)
      img_data = UIImageJPEGRepresentation(fixed_image, 0.8)

      s3_params = get_s3_result[:params].dup
      key = "#{s3_params[:key]}"
      key.slice!('${filename}')
      s3_params[:key] = "#{key}#{BubbleWrap.create_uuid}/${filename}"
      s3_params['Content-Type'] = 'image/jpeg'

      s3_params.merge!(s3_appended_hash) unless s3_appended_hash.nil?
      s3_removed_key_arr.each do |key|
        s3_params.delete(key)
      end unless s3_removed_key_arr.nil?

      @client = AFMotion::Client.build(get_s3_result[:url]) do
        header "Accept", "application/xml"
        response_serializer :xml
      end

      @client.multipart_post('/', s3_params) do |post_s3_result, form_data, progress|
        if form_data
          form_data.appendPartWithFileData(img_data, name: "file", fileName:"ios.jpg", mimeType: "image/jpeg")
        elsif progress
          @events[:progress].call unless @events[:progress].nil?
        elsif post_s3_result.success?
          XMLParser.new.parse_xml(post_s3_result.object,'Key',:delegate) do |s3_key|
            block.call(true, s3_key)
          end
        else
          block.call(false, post_s3_result)
        end
      end
    end

    def onPrepareForRelease
      ap 'PhotoUpload clear_all'
      @events = nil
      @client = nil
    end

    def dealloc
      onPrepareForRelease
      super
    end
  end

end