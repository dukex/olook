
#
# Specifying rufus-scheduler
#
# Fri Oct  7 17:30:45 JST 2011
#

require 'spec_base'


describe SCHEDULER_CLASS do

  before(:each) do
    @s = start_scheduler
  end
  after(:each) do
    stop_scheduler(@s)
  end

  MJOB = Proc.new do |x|
    begin
      $var << "in#{x}"
      sleep 0.500
      $var << "out#{x}"
    rescue Exception => e
      puts '=' * 80
      p e
      puts '=' * 80
    end
  end

  context ':mutex => String' do

    it 'prevents overlapping' do

      $var = ''

      @s.in('1s', :mutex => 'toto') { MJOB.call(0) }
      @s.in('1s', :mutex => 'toto') { MJOB.call(1) }

      sleep 3.0

      %w[ in0out0in1out1 in1out1in0out0 ].should include($var)
    end

    it 'creates a new mutex when the name is first encountered' do

      @s.instance_variable_get(:@mutexes).size.should == 0

      @s.in('1s', :mutex => 'fruit') { sleep 0.1 }

      sleep 1.5

      @s.instance_variable_get(:@mutexes).size.should == 1
    end

    it 'creates a unique mutex for a given name' do

      @s.in('1s', :mutex => 'gum') { sleep 0.1 }
      @s.in('1s', :mutex => 'gum') { sleep 0.1 }

      sleep 1.5

      @s.instance_variable_get(:@mutexes).size.should == 1
    end
  end

  context ':mutex => Mutex' do

    it 'prevents overlapping' do

      $var = ''
      m = Mutex.new

      @s.in('1s', :mutex => m) { MJOB.call(0) }
      @s.in('1s', :mutex => m) { MJOB.call(1) }

      sleep 3.0

      %w[ in0out0in1out1 in1out1in0out0 ].should include($var)
    end

    it 'does not register the mutex' do

      @s.in('1s', :mutex => Mutex.new) { sleep 0.1 }

      sleep 1.5

      @s.instance_variable_get(:@mutexes).size.should == 0
    end
  end
end

