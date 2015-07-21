module ProMotion
  class XLFormScreen < XlFormViewController
    include ProMotion::ScreenModule
    include ProMotion::XLFormModule

    attr_reader :form_object

    def viewDidLoad
      super
      update_form_data

      form_options = self.class.get_form_options

      if form_options[:on_cancel]
        on_cancel = form_options[:on_cancel]
        title     = NSLocalizedString('Cancel', nil)
        item      = :cancel
        if on_cancel.is_a? Hash
          title = on_cancel[:title] if on_cancel[:title]
          item  = on_cancel[:item] if on_cancel[:item]
        end

        set_nav_bar_button :left, {
                                    system_item: item,
                                    title:       title,
                                    action:      'on_cancel:'
                                }
      end

      if form_options[:on_save]
        on_cancel = form_options[:on_save]
        title     = NSLocalizedString('Save', nil)
        item      = :save
        if on_cancel.is_a? Hash
          title = on_cancel[:title] if on_cancel[:title]
          item  = on_cancel[:item] if on_cancel[:item]
        end

        set_nav_bar_button :right, {
                                     system_item: item,
                                     title:       title,
                                     action:      'on_save:'
                                 }
      end
    end

    def form_data
      PM.logger.info "You need to implement a `form_data` method in #{self.class.to_s}."
      []
    end

    def update_form_data
      form_options = self.class.get_form_options
      title        = self.class.title
      required     = form_options[:required]

      @form_builder = PM::XLForm.new(self.form_data,
                                     {
                                         title:    title,
                                         required: required
                                     })
      @form_object  = @form_builder.build
      self.form     = @form_object
    end

    def values
      values = {}
      formValues.each do |key, value|
        if value.is_a? XLFormOptionsObject
          value = value.formValue
        end
        values[key] = value
      end

      values
    end

    def valid?
      validation_errors.empty?
    end

    alias :validation_errors :formValidationErrors

    def display_errors
      return if valid?

      errors = validation_errors.map do |error|
        error.localizedDescription
      end

      if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1
        alert  = UIAlertController.alertControllerWithTitle(NSLocalizedString('Error', nil),
                                                            message:        errors.join(', '),
                                                            preferredStyle: UIAlertControllerStyleAlert)
        action = UIAlertAction.actionWithTitle(NSLocalizedString('OK', nil),
                                               style:   UIAlertActionStyleDefault,
                                               handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
      else
        alert         = UIAlertView.new
        alert.title   = NSLocalizedString('Error', nil)
        alert.message = errors.join(', ')
        alert.show
      end
    end

    protected
    def on_cancel(_)
      form_options = self.class.get_form_options
      if form_options[:on_cancel]
        on_cancel = form_options[:on_cancel]
        if on_cancel.is_a? Hash
          on_cancel = on_cancel[:action]
        end
        try on_cancel
      end
    end

    def on_save(_)
      unless valid?
        display_errors
        return
      end

      form_options = self.class.get_form_options
      if form_options[:on_save]
        on_save = form_options[:on_save]
        if on_save.is_a? Hash
          on_save = on_save[:action]
        end
        try on_save, values
      end
    end

    ## XLFormDescriptorDelegate
    def formSectionHasBeenAdded(section, atIndex: _)
      super
      callback = @form_builder.get_callback(section, :on_add)
      callback.call if callback
    end

    def formSectionHasBeenRemoved(section, atIndex: _)
      super
      callback = @form_builder.get_callback(section, :on_remove)
      callback.call if callback
    end

    def formRowHasBeenAdded(row, atIndexPath: _)
      super
      callback = @form_builder.get_callback(row, :on_add)
      callback.call if callback
    end

    def formRowHasBeenRemoved(row, atIndexPath: _)
      super
      callback = @form_builder.get_callback(row, :on_remove)
      callback.call if callback
    end

    def formRowDescriptorValueHasChanged(row, oldValue: old_value, newValue: new_value)
      super
      callback = @form_builder.get_callback(row, :on_change)
      callback.call(old_value, new_value) if callback
    end

  end
end
