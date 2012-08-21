# encoding: utf-8
module BallotBox
  autoload :Voting,    'ballot_box/voting'
  autoload :Manager,   'ballot_box/manager'
  autoload :Config,    'ballot_box/config'
  autoload :Callbacks, 'ballot_box/callbacks'
  autoload :Base,      'ballot_box/base'
  
  module Strategies
    autoload :Base,          'ballot_box/strategies/base'
    autoload :Authenticated, 'ballot_box/strategies/authenticated'
  end
  
  def self.table_name_prefix
    'ballot_box_'
  end
  
  def self.load_strategy(name)
    case name.class.name
      when "Symbol" then "BallotBox::Strategies::#{name.to_s.classify}".constantize
      when "String" then name.classify.constantize
      else name
    end
  end
end

require 'ballot_box/version'
require 'ballot_box/engine'
