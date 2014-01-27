module Tgios
  class BindingBase
    def initialize(*arg)
      @hook_bindings = []
    end

    def prepareForRelease
      @hook_bindings = nil
      onPrepareForRelease
    end

    def onPrepareForRelease
      raise NotImplementedError.new("prepareForRelease not overridden for class #{self.class.name}")
    end

    def hook(control, event, &block)
      binding=if control.is_a?(UIButton)
                UIButtonBinding.new.bind(control).on(event, &block)
              end

      @hook_bindings << binding
      binding

    end

    def unhook(control, event)
      if control.is_a?(UIButton)
        UIButtonBinding.unbind(control)
      end
    end

    def dealloc
      ap "#{self.class.name} dealloc"
      super
    end
  end

end