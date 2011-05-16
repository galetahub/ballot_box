module BallotBox
  module Base
    def self.included(base)
      base.extend SingletonMethods
    end
    
    module SingletonMethods
      #
      #  ballot_box :counter_cache => true,
      #             :strategies => [:authenticated]
      #
      def ballot_box(options = {})
        extend ClassMethods
        include InstanceMethods
        
        options = { :strategies => [:authenticated] }.merge(options) 
        
        class_attribute :ballot_box_options, :instance_writer => false
        self.ballot_box_options = options
        
        has_many :votes,
          :class_name => 'BallotBox::Vote', 
          :as => :voteable,
          :dependent => :delete_all
        
        attr_accessor :current_vote
        
        define_ballot_box_callbacks :vote
      end
    end
    
    module ClassMethods
    
      def define_ballot_box_callbacks(*callbacks)
        define_callbacks *[callbacks, {:terminator => "result == false"}].flatten
        callbacks.each do |callback|
          eval <<-end_callbacks
            def before_#{callback}(*args, &blk)
              set_callback(:#{callback}, :before, *args, &blk)
            end
            def after_#{callback}(*args, &blk)
              set_callback(:#{callback}, :after, *args, &blk)
            end
          end_callbacks
        end
      end
      
      def ballot_box_cached_column
        if ballot_box_options[:counter_cache] == true
          "votes_count"
        elsif ballot_box_options[:counter_cache]
          ballot_box_options[:counter_cache]
        else
          false
        end
      end
      
      def ballot_box_strategies
        @@ballot_box_strategies ||= ballot_box_options[:strategies].map { |st| BallotBox.load_strategy(st) }
      end
    end
    
    module InstanceMethods
      
      def ballot_box_cached_column
        @ballot_box_cached_column ||= self.class.ballot_box_cached_column
      end
      
      def ballot_box_valid?(vote)
        self.class.ballot_box_strategies.map { |st| st.new(self, vote) }.map(&:valid?).all?
      end
    end
  end
end
