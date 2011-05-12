# encoding: utf-8
require 'rails'
require 'ballot_box'

module BallotBox
  class Engine < ::Rails::Engine
    config.before_initialize do
      ActiveSupport.on_load :active_record do
        ::ActiveRecord::Base.send :include, BallotBox::Base
      end
    end
  end
end
