module BallotBox
  module Base
    def self.included(base)
      base.extend SingletonMethods
    end
    
    module SingletonMethods
      #
      #  ballot_box :counter_cache => true,
      #             :strategies => [:authenticated],
      #             :place => { :column => "place", :order => "votes_count DESC" }
      #
      def ballot_box(options = {})
        extend ClassMethods
        include InstanceMethods
        
        options = { 
          :strategies => [:authenticated], 
          :place => false,
          :refresh => true
        }.merge(options)
        
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
      
      def ballot_box_place_column
        if ballot_box_options[:place] == true
          "place"
        elsif ballot_box_options[:place]
          ballot_box_options[:place]
        else
          false
        end
      end
      
      def ballot_box_strategies
        @@ballot_box_strategies ||= ballot_box_options[:strategies].map { |st| BallotBox.load_strategy(st) }
      end
      
      def ballot_box_update_votes!
        votes_table = BallotBox::Vote.quoted_table_name
        
        query = %(UPDATE #{quoted_table_name} a, 
            (SELECT SUM(value) AS summa, voteable_id, voteable_type 
             FROM #{votes_table} 
             WHERE voteable_type = '#{name}'
             GROUP BY voteable_id, voteable_type) b 
          SET a.#{ballot_box_cached_column} = b.summa
          WHERE a.id = b.voteable_id AND b.voteable_type = '#{name}')
        
        connection.execute(query)
      end
      
      def ballot_box_place_scope
        unscoped.order("#{quoted_table_name}.#{ballot_box_cached_column} DESC")
      end
      
      def ballot_box_update_place!(scope = nil)
        table = quoted_table_name
        subquery = ballot_box_place_scope.select("@row := @row + 1 AS row, #{table}.id").from("#{table}, (SELECT @row := 0) r")
        subquery = subquery.where(scope) if scope
        
        query = %(UPDATE #{table} AS a
          INNER JOIN (
            #{subquery.to_sql}
          ) AS b ON a.id = b.id
          SET a.#{ballot_box_place_column} = b.row;)
        
        connection.execute(query)
      end
    end
    
    module InstanceMethods
      
      def ballot_box_cached_column
        @ballot_box_cached_column ||= self.class.ballot_box_cached_column
      end
      
      def ballot_box_place_column
        @ballot_box_place_column ||= self.class.ballot_box_place_column
      end
      
      def ballot_box_valid?(vote)
        self.class.ballot_box_strategies.map { |st| st.new(self, vote) }.map(&:valid?).all?
      end
      
      def ballot_box_refresh?
        self.class.ballot_box_options[:refresh]
      end
      
      def ballot_box_update_votes!
        if persisted? && ballot_box_cached_column
          count = self.votes.select("SUM(value)")
          self.class.update_all("#{ballot_box_cached_column} = (#{count.to_sql})", ["id = ?", id])
        end
      end
    end
  end
end
