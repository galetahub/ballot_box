require 'spec_helper'

describe BallotBox::Manager do
  include Rack::Test::Methods
  
  before(:each) do
    @work = Work.create(:title => "Work one", :group_id => 1)
  end
  
  it "should create new vote" do
    lambda {
      post "/works/votes", { :id => @work.id }, { 'HTTP_USER_AGENT' => 'Mozilla' }
    }.should change { @work.votes.count }.by(1)
    
    last_response.status.should == 200
    last_response.body.should_not be_blank
  end
  
  it "should not create new vote without user agent" do
    lambda {
      post "/works/votes", { :id => @work.id }
    }.should_not change { @work.votes.count }
    
    last_response.status.should == 422
    last_response.body.should_not be_blank
  end
end
