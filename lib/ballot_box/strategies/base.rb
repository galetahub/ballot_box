require 'active_model/validations'

module BallotBox
  module Strategies
    class Base
      include ActiveModel::Validations
      
      attr_accessor :voteable, :vote, :request
      
      def initialize(voteable, vote)
        @voteable = voteable
        @vote = vote
        @request = vote.request
      end
      
      def read_attribute_for_validation(key)
        @vote[key]
      end
      
      # Returns the Errors object that holds all information about attribute error messages.
      def errors
        @errors ||= ActiveModel::Errors.new(@vote)
      end
    end
  end
end
