module BallotBox
  autoload :Voting,    'ballot_box/voting'
  autoload :Manager,   'ballot_box/manager'
  autoload :Config,    'ballot_box/config'
  autoload :Callbacks, 'ballot_box/callbacks'
  autoload :Base,      'ballot_box/base'
  
  def self.table_name_prefix
    'ballot_box_'
  end
end

require 'ballot_box/engine' if defined?(Rails)
