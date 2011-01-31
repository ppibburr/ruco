# encoding: UTF-8
require File.expand_path('spec/spec_helper')

describe Ruco::Application do
  before do
    @file = 'spec/temp.txt'
    write('')
  end

  def write(content)
    File.open(@file,'w'){|f| f.write(content) }
  end

  def read
    File.read(@file)
  end


  def editor_part(view)
    view.naive_split("\n")[1..-2].join("\n")
  end

  def type(*keys)
    keys.each{|k| app.key k }
  end

  let(:app){ Ruco::Application.new(@file, :lines => 5, :columns => 10) }
  let(:status){ "Ruco #{Ruco::VERSION} -- spec/temp.txt  \n" }
  let(:command){ "^W Exit" }

  it "renders status + editor + command" do
    write("xxx\nyyy\nzzz")
    app.view.should == "#{status}xxx\nyyy\nzzz\n#{command}"
  end

  it "can enter stuff" do
    app.key('2')
    app.key('2')
    app.key(:enter)
    app.key('2')
    app.key(:enter)
    app.view.should == "#{status.sub('.txt ','.txt*')}22\n2\n\n#{command}"
  end

  it "does not enter key-codes" do
    app.key(888)
    app.view.should == "#{status}\n\n\n#{command}"
  end

  it "can execute a command" do
    write("123\n456\n789\n")
    app.key(:"Ctrl+g") # go to line
    app.key('2') # 2
    app.key(:enter)
    app.view.should == "#{status}123\n456\n789\n#{command}"
    app.cursor.should == [2,0] # 0 offset + 1 for statusbar
  end

  it "can resize" do
    write("01234567\n1\n2\n3\n4\n5678910111213\n6\n7\n8")
    app.resize(8, 7)
    app.view.should == "#{status}0123456\n1\n2\n3\n4\n5678910\n#{command}"
  end

  describe 'closing' do
    it "can quit" do
      result = app.key(:"Ctrl+w")
      result.should == :quit
    end

    it "asks before closing changed file -- escape == no" do
      app.key('a')
      app.key(:"Ctrl+w")
      app.view.split("\n").last.should include("Loose changes")
      app.key(:escape).should_not == :quit
      app.key("\n").should_not == :quit
    end

    it "asks before closing changed file -- enter == yes" do
      app.key('a')
      app.key(:"Ctrl+w")
      app.view.split("\n").last.should include("Loose changes")
      app.key(:enter).should == :quit
    end
  end
  
  it "can select all" do
    write("1\n2\n3\n4\n5\n")
    app.key(:down)
    app.key(:"Ctrl+a")
    app.key(:delete)
    app.view.should include("\n\n\n")
  end

  describe 'go to line' do
    it "goes to the line" do
      write("\n\n\n")
      app.key(:"Ctrl+g")
      app.key('2')
      app.key(:enter)
      app.cursor.should == [2,0] # status bar +  2
    end

    it "goes to 1 when strange stuff entered" do
      write("\n\n\n")
      app.key(:"Ctrl+g")
      app.key('0')
      app.key(:enter)
      app.cursor.should == [1,0] # status bar +  1
    end
  end

  describe 'Find and replace' do
    it "stops when nothing is found" do
      write 'abc'
      type :"Ctrl+r", 'x', :enter
      app.view.should_not include("Replace with:")
    end

    it "can find and replace multiple times" do
      write 'xabac'
      type :"Ctrl+r", 'a', :enter
      app.view.should include("Replace with:")
      type 'd', :enter
      app.view.should include("Replace")
      type :enter # replace first
      app.view.should include("Replace")
      type :enter # replace second -> finished
      app.view.should_not include("Replace")
      editor_part(app.view).should == "xdbdc\n\n"
    end

    it "can find and skip replace multiple times" do
      write 'xabac'
      type :"Ctrl+r", 'a', :enter
      app.view.should include("Replace with:")
      type 'd', :enter
      app.view.should include("Replace")
      type 's', :enter # skip
      app.view.should include("Replace")
      type 's', :enter # skip
      app.view.should_not include("Replace")
      editor_part(app.view).should == "xabac\n\n"
    end

    it "can replace all" do
      write '_a_a_a_a'
      type :"Ctrl+r", 'a', :enter
      app.view.should include("Replace with:")
      type 'd', :enter
      app.view.should include("Replace")
      type 's', :enter # skip first
      app.view.should include("Replace")
      type 'a', :enter # all
      app.view.should_not include("Replace")
      editor_part(app.view).should == "_a_d_d_d\n\n"
    end

    it "breaks if neither s nor enter is entered" do
      write 'xabac'
      type :"Ctrl+r", 'a', :enter
      app.view.should include("Replace with:")
      type "d", :enter
      app.view.should include("Replace")
      type 'x', :enter
      app.view.should_not include("Replace")
      editor_part(app.view).should == "xabac\n\n"
    end

    it "reuses find" do
      write 'xabac'
      type :"Ctrl+f", 'a', :enter
      type :"Ctrl+r"
      app.view.should include("Find: a")
      type :enter
      app.view.should include("Replace with:")
    end
  end

  describe :bind do
    it "can execute bound stuff" do
      test = 0
      app.bind :'Ctrl+q' do
        test = 1
      end
      app.key(:'Ctrl+q')
      test.should == 1
    end

    it "can execute an action via bind" do
      test = 0
      app.action :foo do
        test = 1
      end
      app.bind :'Ctrl+q', :foo
      app.key(:'Ctrl+q')
      test.should == 1
    end
  end

  describe 'indentation' do
    it "does not extra-indent when pasting" do
      Ruco.class_eval "Clipboard.copy('ab\n  cd\n  ef')"
      app.key(:tab)
      app.key(:tab)
      app.key(:'Ctrl+v') # paste
      editor_part(app.view).should == "    ab\n  cd\n  ef"
    end

    it "indents when typing" do
      app.key(:tab)
      app.key(:tab)
      app.key(:enter)
      app.key('a')
      editor_part(app.view).should == "    \n    a\n"
    end

    it "indents when at end of line and the next line has more whitespace" do
      write("a\n  b\n")
      app.key(:right)
      app.key(:enter)
      app.key('c')
      editor_part(app.view).should == "a\n  c\n  b"
    end

    it "does not indent when inside line and next line has more whitespace" do
      write("ab\n  b\n")
      app.key(:right)
      app.key(:enter)
      app.key('c')
      editor_part(app.view).should == "a\ncb\n  b"
    end

    it "indents when tabbing on selection" do
      write("ab")
      app.key(:"Shift+right")
      app.key(:tab)
      editor_part(app.view).should == "  ab\n\n"
    end

    it "unindents on Shift+tab" do
      write("  ab\n  cd\n")
      app.key(:"Shift+tab")
      editor_part(app.view).should == "ab\n  cd\n"
    end
  end

  describe '.ruco.rb' do
    it "loads it and can use the bound keys" do
      Tempfile.string_as_file("Ruco.configure{ bind(:'Ctrl+e'){ @editor.insert('TEST') } }") do |file|
        File.stub!(:exist?).and_return true
        File.should_receive(:expand_path).with("~/.ruco.rb").and_return file
        app.view.should_not include('TEST')
        app.key(:"Ctrl+e")
        app.view.should include("TEST")
      end
    end
  end

  describe :save do
    it "just saves" do
      write('')
      app.key('x')
      app.key(:'Ctrl+s')
      read.should == 'x'
    end

    it "warns when saving failed" do
      begin
        `chmod -w #{@file}`
        app.key(:'Ctrl+s')
        app.view.should include('Permission denied')
        app.key(:enter) # retry ?
        app.view.should include('Permission denied')
        app.key(:escape)
        app.view.should_not include('Permission denied')
      ensure
        `chmod +w #{@file}`
      end
    end
  end
end