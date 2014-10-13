require_relative "test_helper.rb"

describe Period do

  let(:p1) {Period.new("P1")}
  let(:p2) {Period.new("P2")}
  let(:p3) {Period.new("P3")}
  
  it "defaults to certain" do
    p1.certainty.must_equal true
  end

  it "maintains record certainty" do
    p1.certainty = false
    p1.certainty.must_equal false
  end

  it "can be created with a name" do
    p1 = Period.new("p1")
    p1.must_be_instance_of Period
    p1.party.must_equal Party.new "p1"
  end

  
  describe "Parsability" do
    it "is parsable with the same text" do
      p1.original_text = "P1"
      p1.parsable?.must_equal true
    end
    it "is unparsable about different text" do
      p1.original_text = "P2"
      p1.parsable?.must_equal false
    end
    it "is parsable about things without original text" do
      p1.parsable?.must_equal true
    end
    it "strips certainty words" do
      p1.original_text = "P1?"
      p1.party.certain = false
      p1.parsable?.must_equal true
    end
  end

  describe "Time String output" do
    it "handles on" do
      str = p1.parse_time_string("David, 1981")
      str.must_equal "David"
      p1.beginning.must_equal TimeSpan.new("1981","1981")
      p1.ending.must_be_nil
      p1.time_string.must_equal "1981"
    end
    it "handles in" do
      str = p1.parse_time_string("David, in 1981")
      str.must_equal "David"
      p1.beginning.must_equal TimeSpan.new(nil,"1981")
      p1.ending.must_equal TimeSpan.new("1981",nil)
      p1.time_string.must_equal "in 1981"
    end
    it "handles by until at least" do
      str = p1.parse_time_string("David, by 1981 until at least 1982")
      str.must_equal "David"
      p1.beginning.must_equal TimeSpan.new(nil,"1981")
      p1.ending.must_equal TimeSpan.new("1982",nil)
      p1.time_string.must_equal "by 1981 until at least 1982"
    end
  end


  describe "Ongoing" do
    before do
      p1.beginning = Date.new(2000)
      p1.ending = Date.new(2000,10,17)
    end
    
    it "is not ongoing if it has a beginning and an end" do
      p1.is_ongoing?.must_equal false
    end
    it "is ongoing if it has a beginning" do
     p2.beginning = Date.new(2000)
     p2.is_ongoing?.must_equal true
    end
    it "is not ongoing if it has no beginning" do
      p2.is_ongoing?.must_equal false
    end
    it "is not onboing if it has an event following it" do
      t = Timeline.new
      p2.beginning = Date.new(2000)
      t.insert(p2)
      t.insert(p3)
      p2.is_ongoing?.must_equal false
    end
  end


  describe "Min and Max Timespans" do
    it "is nil if there are no dates" do
      p1.max_timespan.must_be_nil
    end

    it "is nil if there isn't a beginning" do
      p1.ending = Date.new(2000)
      p1.max_timespan.must_be_nil
    end

    it "is nil if it is not ongoing and has no ending" do
      p1.beginning = Date.new(2000)
      t = Timeline.new
      t.insert(p1)
      t.insert(p2)
      p1.max_timespan.must_be_nil     
    end

    it "calculates properly if there is a begin and an end" do
      p1.beginning = Date.new(2000)
      p1.ending = Date.new(2001)
      p1.max_timespan.must_be_instance_of TimeSpan
      p1.max_timespan.earliest.must_equal Date.new(2000,1,1)
      p1.max_timespan.latest.must_equal Date.new(2001,12,31)
      p1.max_timespan.earliest.precision.must_equal DateTimePrecision::DAY
      p1.max_timespan.latest.precision.must_equal DateTimePrecision::DAY
    end

    it "is correct if it is ongoing" do
      p1.beginning = Date.new(2000)
      p1.is_ongoing?.must_equal true
      p1.max_timespan.latest.must_equal Date.today
    end
  end

  describe "Certainty" do
    it "is nil by default" do
      p1.earliest_possible.must_be_nil
      p1.latest_possible.must_be_nil
    end
    it "gives its own earliest if it has one" do
      p1.beginning=Date.new(2000)
      p1.earliest_possible.must_equal p1.begin_of_the_begin 
    end    
    it "gives its own latest if it has one" do
      p1.ending = Date.new(2000)
      p1.latest_possible.must_equal p1.end_of_the_end 
    end

    it "earliest returns the previous end if it exists" do
      t = Timeline.new
      p2.beginning = Date.new(1995) 
      p2.ending = Date.new(2000) 
      t.insert p2
      t.insert p1
      p1.earliest_possible.must_equal p2.begin_of_the_end
    end

    it "latest_possible returns the following beginning if it exists" do
      t = Timeline.new
      p1.beginning = Date.new(1995) 
      p1.ending = Date.new(2000) 
      t.insert p2
      t.insert p1
      p2.latest_possible.must_equal p1.end_of_the_begin
    end

    it "returns the previous begin if it exists" do
      t = Timeline.new
      p2.beginning = Date.new(2000) 
      t.insert p2
      t.insert p1
      p1.earliest_possible.must_equal p2.end_of_the_begin
    end

     it "latest_possible returns the following ending if it exists" do
      t = Timeline.new
      p2.ending = Date.new(2000) 
      t.insert p1
      t.insert p2
      p1.latest_possible.must_equal p2.begin_of_the_end
    end


    it "returns nil if linked dates don't have dates" do
      t = Timeline.new
      t.insert p3
      t.insert p2
      t.insert p1
      p1.earliest_possible.must_be_nil 
      p3.latest_possible.must_be_nil
    end
    it "follows multiple links backwards" do
      t = Timeline.new
      t.insert p1
      t.insert p2
      t.insert p3
      p1.beginning = Date.new(2000)
      p3.ending = Date.new(2001)
      p3.earliest_possible.must_equal p1.end_of_the_begin
      p1.latest_possible.must_equal p3.begin_of_the_end
    end

    
  end

  describe "Provenance" do
      it "generates a record" do
        p1.provenance.must_be_instance_of String
      end
      it "by default is just the name" do 
        p1.provenance.must_equal p1.party.to_s
      end
      it "displays provenance as its to_s" do
        p1.to_s.must_equal p1.provenance
      end
  end

  describe "Footnotes" do
    it "allows footnotes to be assigned" do
      p1.note = "This is a test note"
      p1.note.must_equal "This is a test note"
    end
    it "allows footnote assignment in the init" do
      px = Period.new("test",{note: "test_note"})
      px.note.must_equal "test_note"
    end
    it "returns nil if there isn't a footnote" do
      p1.note.must_be_nil
    end
    it "allows generation with a footnote" do
      p1.note = "I should be a footnote"
      p1.provenance_with_note.must_equal "#{p1.party} [1]. 1. #{p1.note}"
    end
  end
  
  describe "Locations" do
    before do
      @name = "Sgt. Mustard"
      @loc =  "The Billiard room"
      @period = Period.new(@name, {location: @loc})
    end

    it "can have an optional location" do
      @period.location.must_equal Location.new @loc
    end

    it "generates the location as part of provenance" do
      @period.provenance.must_equal "#{@name}, #{@loc}"
    end
  end

  describe "Dates" do
    before do
      p1.beginning = Date.new(2013)      
      p1.ending = Date.new(2014)      
    
    end
    it "does not by default have a beginning or ending" do
      p2.beginning.must_be_nil
      p2.ending.must_be_nil
    end
    it "can initialize a beginning" do
      p1.beginning.must_be_instance_of TimeSpan
      p1.beginning.earliest.must_equal Date.new(2013,1,1)
      p1.beginning.latest.must_equal Date.new(2013,12,31)
    end
    it "can initialize a ending" do
      p1.ending.must_be_instance_of TimeSpan
      p1.ending.earliest.must_equal Date.new(2014,1,1)
      p1.ending.latest.must_equal Date.new(2014,12,31)
    end
    it "does not have dates if not set" do
      p2.botb.must_be_nil
      p2.bote.must_be_nil
      p2.eotb.must_be_nil
      p2.eote.must_be_nil
    end
    it "has a botb" do
      p1.botb.must_equal Date.new(2013,1,1)
      p1.begin_of_the_begin.must_equal Date.new(2013,1,1) 
    end
    it "has a eotb" do
      p1.eotb.must_equal Date.new(2013,12,31)
      p1.end_of_the_begin.must_equal Date.new(2013,12,31)

    end
    it "has a bote" do
      p1.bote.must_equal Date.new(2014,1,1)
      p1.begin_of_the_end.must_equal Date.new(2014,1,1)
    end
    it "has a eote" do
      p1.eote.must_equal Date.new(2014,12,31)
      p1.end_of_the_end.must_equal Date.new(2014,12,31)
    end
  end
end