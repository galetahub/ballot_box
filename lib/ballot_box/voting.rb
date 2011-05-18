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
          before_save :parse_browser
          after_save :update_cached_columns
          after_destroy :update_cached_columns

          attr_accessible :request
          
          composed_of :ip,
            :class_name => 'IPAddr',
            :mapping => %w(ip_address to_i),
            :constructor => Proc.new { |ip_address| IPAddr.new(ip_address, Socket::AF_INET) },
            :converter => Proc.new { |value| value.is_a?(Integer) ? IPAddr.new(value, Socket::AF_INET) : IPAddr.new(value.to_s) }
          
          scope :with_voteable, lambda { |record| where(["voteable_id = ? AND voteable_type = ?", record.id, record.class.name]) }
        end
      end
      
      def chart(mode)
        result = case mode.to_s.downcase
          when 'dates' then chart_dates
          when 'browsers' then chart_browsers
          when 'platforms' then chart_platforms
        end
        
        [ result ].to_json
      end
      
      protected
      
        def chart_dates
          data = scoped.select("DATE(created_at) AS created_at, SUM(value) AS rating").group("DATE(created_at)").all
          data.collect { |item| [ item.created_at, item.rating.to_i ] }
        end
        
        def chart_browsers
          data = scoped.select("browser_name, SUM(value) AS rating").group("browser_name").all
          data.collect { |item| [ item.browser_name, item.rating.to_i ] }
        end
        
        def chart_platforms
          data = scoped.select("browser_platform, SUM(value) AS rating").group("browser_platform").all
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
      
        def parse_browser
          self.browser_name = browser.id.to_s
          self.browser_version = browser.version
          self.browser_platform = browser.platform.to_s
        end
        
        def update_cached_columns
          if voteable && voteable.ballot_box_cached_column
            count = voteable.votes.select("SUM(value)")
            voteable.class.update_all("#{voteable.ballot_box_cached_column} = (#{count.to_sql})", ["id = ?", voteable.id])
          end
        end
    end
  end
end
