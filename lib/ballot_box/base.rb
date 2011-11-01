module BallotBox
  module Base
    def self.included(base)
      base.extend SingletonMethods
    end
    
    module SingletonMethods
      #
      #  ballot_box :counter_cache => true,
      #             :strategies => [:authenticated],
      #             :place => :position,
      #             :scope => :group_id
      #
      def ballot_box(options = {})
        extend ClassMethods
        include InstanceMethods
        
        default_options = { 
          :strategies => [:authenticated],
          :counter_cache => false, 
          :place => false,
          :refresh => true,
          :scope => nil
        }
        
        options.assert_valid_keys(default_options.keys)
        options = default_options.merge(options)
        
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
      
      def ballot_box_update_place!(record = nil)
        relation = ballot_box_place_scope
        
        if ballot_box_options[:scope]
          scope_columns = Array.wrap(ballot_box_options[:scope])
          
          unless record.nil?
            scope_columns.each do |scope_item|
              scope_value = record.send(scope_item)
              relation = relation.where(scope_item => scope_value)
            end
          else
            unscoped.select(scope_columns).group(scope_columns).each do |record|
              ballot_box_update_place!(record)
            end
            
            return
          end
        end
        
        ballot_box_update_place_by_relation(relation)
      end
      
      def ballot_box_update_place_by_relation(relation)
        table = quoted_table_name
        
        relation = relation.select("@row := @row + 1 AS row, #{table}.id").from("#{table}, (SELECT @row := 0) r")
        
        query = %(UPDATE #{table} AS a
          INNER JOIN (
            #{relation.to_sql}
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
      
      def ballot_box_update_place!
        if persisted? && ballot_box_place_column
          self.class.ballot_box_update_place!(self)
        end
      end
    end
  end
end
