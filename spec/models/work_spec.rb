require 'spec_helper'

describe Work do
  context "class methods" do
    it "should return cached column" do
      Work.ballot_box_cached_column.to_s.should == "rating"
    end
    
    it "should return place column" do
      Work.ballot_box_place_column.to_s.should == "position"
    end
    
    it "should return ballot_box options" do
      Work.ballot_box_options.should be_a(Hash)
      
      Work.ballot_box_options[:counter_cache].should == :rating
      Work.ballot_box_options[:strategies].should == ['SmsStrategy']
      Work.ballot_box_options[:place].should == :position
      Work.ballot_box_options[:refresh].should == false
      Work.ballot_box_options[:scope].should == :group_id
    end
  end
  
  context "counters" do
    before(:all) do
      vote_attributes = {
        :ip => '195.34.91.163', 
        :user_agent => 'Mozilla/5.0 (X11; Linux i686; rv:7.0.1) Gecko/20100101 Firefox/7.0.1',
        :value => 1
      }
      
      @works1 = []
      @works2 = []
      
      (1..5).to_a.each { |n| @works1 << Work.create(:title => "Work #{n}", :group_id => 1) }
      (1..6).to_a.each { |n| @works2 << Work.create(:title => "Work #{n}", :group_id => 2) }
      
      @works = [@works1, @works2].flatten
      
      @works.each_with_index do |work, index|
        (index + 1).times do 
          work.votes.create do |v|
            v.ip = vote_attributes[:ip]
            v.user_agent = vote_attributes[:user_agent]
            v.value = vote_attributes[:value]
          end
        end
      end
      
      Work.ballot_box_update_votes!
      Work.ballot_box_update_place!
      
      @works.map(&:reload)
    end
    
    it "should calculate all work votes" do      
      @works1.each_with_index do |work, index|
        work.rating.should == (index + 1)
      end
      
      @works2.each_with_index do |work, index|
        work.rating.should == (index + 1 + @works1.size)
      end
    end
    
    it "should calculate all works position" do
      @works1.reverse.each_with_index do |work, index|
        work.position.should == (index + 1)
      end
      
      @works2.reverse.each_with_index do |work, index|
        work.position.should == (index + 1)
      end
    end
  end
end
