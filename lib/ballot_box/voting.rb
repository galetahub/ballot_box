# encoding: utf-8
require 'ipaddr'
require "browser"

module BallotBox
  module Voting
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
    end
    
    module ClassMethods
      def self.extended(base)
        base.class_eval do
          # Associations
          belongs_to :voteable, :polymorphic => true
          belongs_to :voter, :polymorphic => true
          
          # Validations
          validates_presence_of :ip_address, :user_agent, :voteable_id, :voteable_type
          validates_numericality_of :value, :only_integer => true
          
          # Callbacks
          before_create :parse_browser
          after_save :update_cached_columns, :if => :refresh?
          after_destroy :update_cached_columns, :if => :refresh?

          attr_accessible :request, :ip_address, :user_agent
          
          composed_of :ip,
            :class_name => 'IPAddr',
            :mapping => %w(ip_address to_i),
            :constructor => Proc.new { |ip_address| IPAddr.new(ip_address, Socket::AF_INET) },
            :converter => Proc.new { |value| value.is_a?(Integer) ? IPAddr.new(value, Socket::AF_INET) : IPAddr.new(value.to_s) }
          
          scope :with_voteable, lambda { |record| where(["voteable_id = ? AND voteable_type = ?", record.id, record.class.name]) }
        end
      end
      
      def chart(mode)
        case mode.to_s.downcase
          when 'dates' then [chart_dates]
          when 'browsers' then [chart_browsers]
          when 'platforms' then [chart_platforms]
          when 'dates_browsers' then chart_dates_browsers
        end
      end
      
      protected
        
        # Simple little alias
        def tn
          quoted_table_name
        end
        
        def chart_dates_browsers
          result = []
          t = quoted_table_name
          cols = ["DATE(#{tn}.created_at) AS created_at", 
                  "SUM(#{tn}.value) AS rating", 
                  "#{tn}.browser_name"]
                  
          data = scoped.select(cols.join(',')).group("DATE(#{tn}.created_at), #{tn}.browser_name").all
          
          result << { 
            :name => "total", 
            :data => data.group_by(&:created_at).collect { |created_at, items| [created_at, items.sum(&:rating).to_i ] }
          }
          
          data.group_by(&:browser_name).each do |browser_name, items|
            result << { 
              :name => browser_name, 
              :data => items.collect { |item| [ item.created_at, item.rating.to_i ] } 
            }
          end
          
          result
        end
        
        def chart_dates
          t = quoted_table_name
          cols = ["DATE(#{tn}.created_at) AS created_at", "SUM(#{tn}.value) AS rating"]
          data = scoped.select(cols.join(',')).group("DATE(#{tn}.created_at)").all
          data.collect { |item| [ item.created_at, item.rating.to_i ] }
        end
        
        def chart_browsers
          t = quoted_table_name
          data = scoped.select("#{tn}.browser_name, SUM(#{tn}.value) AS rating").group("#{tn}.browser_name").all
          data.collect { |item| [ item.browser_name, item.rating.to_i ] }
        end
        
        def chart_platforms
          data = scoped.select("#{tn}.browser_platform, SUM(#{tn}.value) AS rating").group("#{tn}.browser_platform").all
          data.collect { |item| [ item.browser_platform, item.rating.to_i ] }
        end
    end
    
    module InstanceMethods
    
      def browser
        @browser ||= Browser.new(:ua => user_agent, :accept_language => "en-us")
      end
      
      def anonymous?
        voter.nil?
      end
      
      def as_json(options = nil)
        options = { 
          :methods => [:ip], 
          :only => [:referrer, :value, :browser_version, :browser_name, :user_agent, :browser_platform ] 
        }.merge(options || {})
        
        super
      end
      
      def request
        @request
      end
      
      def request=(req)
        self.ip = req.ip
        self.user_agent = req.user_agent
        self.referrer = req.referer
        self.voteable_id = req.params["id"]
        @request = req
      end
      
      def call
        if register
          [self.to_json, 200]
        else
          [self.errors.to_json, 422]
        end
      end
      
      def register
        if voteable && voteable.ballot_box_valid?(self)
          voteable.current_vote = self
          
          voteable.run_callbacks(:vote) do
            errors.empty? && save
          end
        end
      end
      
      protected
      
        def refresh?
          voteable && voteable.ballot_box_refresh?
        end
      
        def parse_browser
          self.browser_name ||= browser.id.to_s
          self.browser_version ||= browser.version
          self.browser_platform ||= browser.platform.to_s
        end
        
        def update_cached_columns
          update_votes_count
          update_place
        end
        
        def update_votes_count
          voteable.ballot_box_update_votes!
        end
        
        def update_place
          if voteable.ballot_box_place_column
            voteable.class.ballot_box_update_place!
          end
        end
    end
  end
end
