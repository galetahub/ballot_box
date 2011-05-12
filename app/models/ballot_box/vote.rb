module BallotBox
  class Vote < ::ActiveRecord::Base
    include BallotBox::Voting
  end
end
