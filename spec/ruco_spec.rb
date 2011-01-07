require File.expand_path('spec/spec_helper')

describe Ruco do
  def write(content)
    File.open(@file,'w'){|f| f.write(content) }
  end

  let(:editor){ Ruco::Editor.new(@file, :lines => 3, :columns => 5) }

  it "has a VERSION" do
    Ruco::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end

  describe 'moving' do
    before do
      @file = 'spec/temp.txt'
      write("    \n    \n    ")
    end

    it "starts at 0,0" do
      editor.line.should == 0
      editor.column.should == 0
    end

    it "can move" do
      editor.move(1,2)
      editor.line.should == 1
      editor.column.should == 2
      editor.move(1,1)
      editor.line.should == 2
      editor.column.should == 3
    end

    it "cannot move left/top off screen" do
      editor.move(-1,-1)
      editor.line.should == 0
      editor.column.should == 0
    end

    it "cannot move right of characters" do
      editor.move(2,6)
      editor.line.should == 2
      editor.column.should == 4
    end

    it "gets reset to empty newline when moving past lines" do
      editor.move(6,3)
      editor.line.should == 3
      editor.column.should == 0
    end
  end

  describe 'viewing' do
    before do
      @file = 'spec/temp.txt'
      write('')
    end

    it "displays an empty screen" do
      editor.view.should == "\n\n\n"
    end

    it "displays short file content" do
      write('xxx')
      editor.view.should == "xxx\n\n\n"
    end

    it "displays long file content" do
      write('1234567')
      editor.view.should == "12345\n\n\n"
    end

    it "displays multiline-file content" do
      write("xxx\nyyy\nzzz\niii")
      editor.view.should == "xxx\nyyy\nzzz\n"
    end
  end
end
