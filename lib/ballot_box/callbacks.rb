# encoding: utf-8
module BallotBox
  module Callbacks
    # Hook to _run_callbacks asserting for conditions.
    def _run_callbacks(kind, *args) #:nodoc:
      options = args.last # Last callback arg MUST be a Hash

      send("_#{kind}").each do |callback, conditions|
        invalid = conditions.find do |key, value|
          value.is_a?(Array) ? !value.include?(options[key]) : (value != options[key])
        end

        callback.call(*args) unless invalid
      end
    end
    
    # A callback that runs before create vote
    # Example:
    #   BallotBox::Manager.before_vote do |env, opts|
    #   end
    #
    def before_vote(options = {}, method = :push, &block)
      raise BlockNotGiven unless block_given?
      _before_vote.send(method, [block, options])
    end
    
    # Provides access to the callback array for before_vote
    # :api: private
    def _before_vote
      @_before_vote ||= []
    end
    
    # A callback that runs after vote created
    # Example:
    #   BallotBox::Manager.after_vote do |env, opts|
    #   end
    #
    def after_vote(options = {}, method = :push, &block)
      raise BlockNotGiven unless block_given?
      _after_vote.send(method, [block, options])
    end
    
    # Provides access to the callback array for before_vote
    # :api: private
    def _after_vote
      @_after_vote ||= []
    end
  end
end
