# encoding: utf-8
module BallotBox
  class Config < Hash
    # Creates an accessor that simply sets and reads a key in the hash:
    #
    # class Config < Hash
    #   hash_accessor :routes
    # end
    #
    # config = Config.new
    # config.routes = {'/posts/vote' => 'Post' }
    # config[:routes] #=> {'/posts/vote' => 'Post' }
    #
    def self.hash_accessor(*names) #:nodoc:
      names.each do |name|
        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{name}
            self[:#{name}]
          end

          def #{name}=(value)
            self[:#{name}] = value
          end
        METHOD
      end
    end
    
    hash_accessor :routes
    
    def initialize(other={})
      merge!(other)
      self[:routes] ||= { "/ballot_box/vote" => 'Class' }
    end
  end
end
