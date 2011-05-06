require 'rails'
require 'falcon'

module Falcon
  class Engine < ::Rails::Engine
    config.before_initialize do
      ActiveSupport.on_load :active_record do
        ::ActiveRecord::Base.send :include, Falcon::Base
      end
    end
  end
end
