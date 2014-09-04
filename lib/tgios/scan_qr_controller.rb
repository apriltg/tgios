module Tgios
  class ScanQrController < UIViewController
    def viewDidLoad
      super
      self.view.backgroundColor = :dark_gray.uicolor
      @load_view = Tgios::LoadingView.add_loading_view_to(self.view)
      @load_view.start_loading
      if Device.simulator?
        self.performSelector('fake_scan', withObject: nil, afterDelay: 3)
      else
        self.performSelector('startScanning', withObject: nil, afterDelay: 0.5)
      end

    end

    def startScanning
      @load_view.stop_loading
      setupCapture
    end

    def setupCapture
      #NSLog "setCapture()"

      @session = AVCaptureSession.alloc.init
      @session.sessionPreset = AVCaptureSessionPresetHigh

      @device = AVCaptureDevice.defaultDeviceWithMediaType AVMediaTypeVideo
      @error = Pointer.new('@')
      @input = AVCaptureDeviceInput.deviceInputWithDevice @device, error: @error

      @previewLayer = AVCaptureVideoPreviewLayer.alloc.initWithSession(@session)
      @previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
      layerRect = self.view.layer.bounds
      @previewLayer.bounds = layerRect
      @previewLayer.setPosition(CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect)))
      self.view.layer.addSublayer(@previewLayer)

      @queue = Dispatch::Queue.new('camQueue')
      @output = AVCaptureMetadataOutput.alloc.init
      @output.setMetadataObjectsDelegate self, queue: @queue.dispatch_object

      @session.addInput @input
      @session.addOutput @output
      @output.metadataObjectTypes = [ AVMetadataObjectTypeQRCode ]

      @isScanning = true

      @session.startRunning
      #NSLog "session running: #{@session.running?}"



      camera_size = layerRect.size
      sq_size = 240
      sq_border = 20
      line_length = 60
      sq_x = (camera_size.width - sq_size) / 2
      sq_y = (camera_size.height - sq_size) / 2
      v_height = sq_size - sq_border * 2
      border_color = :white.cgcolor(0.8)

      square = Base.style(CALayer.layer, {frame: [[sq_x, sq_y],[sq_size, sq_size]]})

      top_left = Base.style(CALayer.layer, frame: [[0, 0], [line_length, sq_border]], backgroundColor: border_color)
      top_right = Base.style(CALayer.layer, frame: [[sq_size-line_length, 0], [line_length, sq_border]], backgroundColor: border_color)
      left_top = Base.style(CALayer.layer, frame: [[0, sq_border], [sq_border, line_length - sq_border]], backgroundColor: border_color)
      right_top = Base.style(CALayer.layer, frame: [[sq_size - sq_border, sq_border], [sq_border, line_length - sq_border]], backgroundColor: border_color)
      left_bottom = Base.style(CALayer.layer, frame: [[0, sq_size - line_length], [sq_border, line_length - sq_border]], backgroundColor: border_color)
      right_bottom = Base.style(CALayer.layer, frame: [[sq_size - sq_border, sq_size - line_length], [sq_border, line_length - sq_border]], backgroundColor: border_color)
      bottom_left = Base.style(CALayer.layer, frame: [[0, sq_size - sq_border], [line_length, sq_border]], backgroundColor: border_color)
      bottom_right = Base.style(CALayer.layer, frame: [[sq_size-line_length, sq_size - sq_border], [line_length, sq_border]], backgroundColor: border_color)

      square.addSublayer top_left
      square.addSublayer top_right
      square.addSublayer left_top
      square.addSublayer right_top
      square.addSublayer left_bottom
      square.addSublayer right_bottom
      square.addSublayer bottom_left
      square.addSublayer bottom_right

      self.view.layer.addSublayer square

      true
    end

    def captureOutput(captureOutput, didOutputMetadataObjects: metadataObjects, fromConnection: connection)

      metadataObject = metadataObjects[0]

      if !@scanned && metadataObject.present? && metadataObject.type == AVMetadataObjectTypeQRCode
        @scanned = true
        #NSLog "#{metadataObjects[0].stringValue}"


        self.performSelectorOnMainThread('openQRCode:', withObject: metadataObject.stringValue, waitUntilDone: false)
      end
    end

    def openQRCode(result)
      #NSLog "openQRCode()"

      stop_scanning

      @events[:result_scanned].call(result)
      self.dismissViewControllerAnimated(true, completion: nil)
    end

    def stop_scanning

      NSObject.cancelPreviousPerformRequestsWithTarget(self)

      if @isScanning
        @isScanning = false

        @session.stopRunning
        #NSLog "session running: #{@session.running?}"

        @previewLayer.removeFromSuperlayer
        @previewLayer = nil

        @session = nil
      end
      self.navigationItem.leftBarButtonItem = nil
    end

    def fake_scan
      @load_view.stop_loading
      @isScanning = false
      @events[:fake_result].call do |result|
        fake_result = result
      end unless @events[:fake_result].nil?
      fake_result ||= "#{rand(100)+1}"
      openQRCode(fake_result)
    end

    def on(event, &block)
      @events[event] = block.weak!
      self
    end

    def init
      super
      @events={}
      self
    end

    def dealloc
      ap "#{self.class.name} dealloc"
      super
    end

  end
end
