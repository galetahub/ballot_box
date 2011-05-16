module BallotBox
  module Strategies
    class Authenticated < Base
      validates_presence_of :voter
    end
  end
end
