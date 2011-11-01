class Work < ActiveRecord::Base
  ballot_box :counter_cache => :rating, 
             :strategies => ['SmsStrategy'],
             :place => :position, 
             :refresh => false,
             :scope => :group_id
end
