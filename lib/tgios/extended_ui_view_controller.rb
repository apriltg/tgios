module Tgios
  class ExtendedUIViewController < UIViewController
    def viewDidLoad
      super
      self.edgesForExtendedLayout = UIRectEdgeNone if self.respond_to?(:edgesForExtendedLayout)
      @bindings=[]
    end

    def prepareForRelease
      @bindings=nil
      onPrepareForRelease
    end

    def onPrepareForRelease
      raise NotImplementedError.new("onPrepareForRelease not overridden for class #{self.class.name}")
    end

    def hook(control, event, &block)
      binding=if control.is_a?(UIButton)
                UIButtonBinding.new.bind(control).on(event, &block)
              end

      @bindings << binding
      binding

    end

    def unhook(control, event)
      if control.is_a?(UIButton)
        UIButtonBinding.unbind(control)
      end
    end

    def viewDidDisappear(animated)
      if self.isMovingFromParentViewController
        ap "#{self.class.name} view moving away, prepare for release"
        # cut off all crap to avoid memory leak
        self.prepareForRelease()
      end
      super
    end

    def dismissViewControllerAnimated(flag, completion:completion)
      super(flag, ->{
        self.prepareForRelease()
        completion.call unless completion.nil?
      })
    end

    def dealloc
      ap "#{self.class.name} dealloc"
      super
    end
  end
end