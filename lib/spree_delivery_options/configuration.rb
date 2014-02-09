module SpreeDeliveryOptions
  class Configuration < Spree::Preferences::Configuration
    preference :delivery_cut_off_hour, :integer, default: 12
    preference :delivery_leadtime_days, :integer, default: 1
    preference :delivery_time_options, :string, default: {monday: ['Between 6am-8am']}.to_json
  end
end
