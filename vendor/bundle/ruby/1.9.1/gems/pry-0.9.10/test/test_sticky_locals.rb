require 'helper'

describe "Sticky locals (_file_ and friends)" do
  it 'locals should all exist upon initialization' do
    mock_pry("_file_").should.not =~ /NameError/
    mock_pry("_dir_").should.not =~ /NameError/
    mock_pry("_ex_").should.not =~ /NameError/
    mock_pry("_pry_").should.not =~ /NameError/
    mock_pry("_").should.not =~ /NameError/
  end

  it 'locals should still exist after cd-ing into a new context' do
    mock_pry("cd 0", "_file_").should.not =~ /NameError/
    mock_pry("cd 0","_dir_").should.not =~ /NameError/
    mock_pry("cd 0","_ex_").should.not =~ /NameError/
    mock_pry("cd 0","_pry_").should.not =~ /NameError/
    mock_pry("cd 0","_").should.not =~ /NameError/
  end

  it 'locals should keep value after cd-ing(_pry_ and _ex_)' do
    mock_pry("$x = _pry_;", "cd 0", "_pry_ == $x").should =~ /true/
    mock_pry("error blah;", "$x = _ex_;", "cd 0", "_ex_ == $x").should =~ /true/
  end

  it 'locals should keep value after cd-ing (_file_ and _dir_)' do
    Pry.commands.command "file-and-dir-test" do
      set_file_and_dir_locals("/blah/ostrich.rb")
    end

    mock_pry("file-and-dir-test", "cd 0", "_file_").should =~ /\/blah\/ostrich\.rb/
    a = mock_pry("file-and-dir-test", "cd 0", "_dir_").should =~ /\/blah/
    Pry.commands.delete "file-and-dir-test"
  end

  describe "User defined sticky locals" do
    describe "setting as Pry.config option" do
      it 'should define a new sticky local for the session (normal value)' do
        Pry.config.extra_sticky_locals[:test_local] = :john

        o = Object.new
        redirect_pry_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Pry.start(o)
        end

        o.instance_variable_get(:@value).should == :john
        Pry.config.extra_sticky_locals = {}
      end

      it 'should define a new sticky local for the session (proc)' do
        Pry.config.extra_sticky_locals[:test_local] = proc { :john }

        o = Object.new
        redirect_pry_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Pry.start(o)
        end

        o.instance_variable_get(:@value).should == :john
        Pry.config.extra_sticky_locals = {}
      end

    end

    describe "passing in as hash option when creating pry instance" do
      it 'should define a new sticky local for the session (normal value)' do
        o = Object.new
        redirect_pry_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Pry.start(o, :extra_sticky_locals => { :test_local => :john } )
        end

        o.instance_variable_get(:@value).should == :john
      end

      it 'should define multiple sticky locals' do
        o = Object.new
        redirect_pry_io(InputTester.new("@value1 = test_local1",
                                        "@value2 = test_local2",
                                        "exit-all")) do
          Pry.start(o, :extra_sticky_locals => { :test_local1 => :john ,
                      :test_local2 => :carl} )
        end

        o.instance_variable_get(:@value1).should == :john
        o.instance_variable_get(:@value2).should == :carl
      end


      it 'should define a new sticky local for the session (as Proc)' do
        o = Object.new
        redirect_pry_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Pry.start(o, :extra_sticky_locals => { :test_local => proc { :john }} )
        end

        o.instance_variable_get(:@value).should == :john
      end
    end

    describe "hash option value should override config value" do
      it 'should define a new sticky local for the session (normal value)' do
        Pry.config.extra_sticky_locals[:test_local] = :john

        o = Object.new
        redirect_pry_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Pry.start(o, :extra_sticky_locals => { :test_local => :carl })
        end

        o.instance_variable_get(:@value).should == :carl
        Pry.config.extra_sticky_locals = {}
      end
    end

    it 'should create a new sticky local' do
      o = Object.new
      pi = Pry.new
      pi.add_sticky_local(:test_local) { :test_value }
      pi.input, pi.output = InputTester.new("@value = test_local", "exit-all"), StringIO.new
      pi.repl(o)

      o.instance_variable_get(:@value).should == :test_value
    end

    it 'should still exist after cd-ing into new binding' do
      o = Object.new
      o2 = Object.new
      o.instance_variable_set(:@o2, o2)
      pi = Pry.new
      pi.add_sticky_local(:test_local) { :test_value }
      pi.input = InputTester.new("cd @o2\n",
                                 "@value = test_local", "exit-all")
      pi.output = StringIO.new
      pi.repl(o)

      o2.instance_variable_get(:@value).should == :test_value
    end

    it 'should provide different values for successive block invocations' do
      o = Object.new
      pi = Pry.new
      v = [1, 2]
      pi.add_sticky_local(:test_local) { v.shift }
      pi.input = InputTester.new("@value1 = test_local",
                                 "@value2 = test_local", "exit-all")
      pi.output = StringIO.new
      pi.repl(o)

      o.instance_variable_get(:@value1).should == 1
      o.instance_variable_get(:@value2).should == 2
    end
  end

end
