class SmsStrategy < BallotBox::Strategies::Base
  validate :check_group
  
  protected
  
    def check_group
      errors.add(:voteable, :invalid) if voteable.group_id == 100
    end
end
