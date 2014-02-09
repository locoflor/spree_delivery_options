Spree::Order.class_eval do
  require 'date'
  require 'spree/order/checkout'

  def valid_delivery_instructions?
    if self.delivery_instructions.length > 500
      self.errors[:delivery_instructions] << 'cannot be longer than 500 charachters'
      return false
    end
    true
  end

  def valid_delivery_date?

    self.errors[:delivery_date] << 'cannot be blank' unless self.delivery_date

    lead_time = SpreeDeliveryOptions::Config.delivery_leadtime_days

    if self.delivery_date
      self.errors[:delivery_date] << "Delivery date must be at leeast #{lead_time.day.from_now.to_date} from now" if self.delivery_date <= lead_time.days.from_now

      options = week_day_options(self.delivery_date)
      unless options
        self.errors[:delivery_date] << "is not available on the selected week day."
      end

      lead_time = SpreeDeliveryOptions::Config.delivery_leadtime_days
      cutoff_time = Time.now.change(hour: SpreeDeliveryOptions::Config.delivery_cut_off_hour)
      if self.delivery_date == lead_time.day.from_now.to_date && Time.now > cutoff_time
        self.errors[:delivery_date] << "cannot be #{self.delivery_date} if the order is created after #{SpreeDeliveryOptions::Config.delivery_cut_off_hour}"
      end
    end

    self.errors[:delivery_date].empty? ? true : false
  end

  def valid_delivery_time?
    return unless self.delivery_date

    self.errors[:delivery_time] << 'cannot be blank' unless self.delivery_time

    if self.delivery_time
      self.errors[:delivery_time] << 'is invalid' unless (week_day_options(self.delivery_date) && week_day_options(self.delivery_date).include?(self.delivery_time))
    end

    self.errors[:delivery_time].empty? ? true : false
  end

  private

  def week_day_options(date)
    week_day = date.strftime("%A")
    delivery_options[week_day.downcase]
  end

  def delivery_options
    @delivery_options ||= JSON.parse(SpreeDeliveryOptions::Config.delivery_time_options)
  end

end

Spree::PermittedAttributes.checkout_attributes << :delivery_date
Spree::PermittedAttributes.checkout_attributes << :delivery_time
Spree::PermittedAttributes.checkout_attributes << :delivery_instructions

Spree::Order.state_machine.before_transition :to => :payment, :do => :valid_delivery_instructions?
Spree::Order.state_machine.before_transition :to => :payment, :do => :valid_delivery_date?
Spree::Order.state_machine.before_transition :to => :payment, :do => :valid_delivery_time?

