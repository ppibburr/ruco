Commandline editor written in ruby

Alpha, lets see if this works...

Finished:

 - viewing / scrolling / editing / saving / creating
 - Home/End + Page up/down
 - basic Tab support (tab == 2 space)
 - change-indicator (*)
 - writeable indicator (!)
 - backspace / delete
 - find / go to line
 - delete line
 - configuration via `~/.ruco.rb`
 - keeps indentation
 - paste from clipboard (default: Ctrl+v)

Install
=======
    sudo gem install ruco

Usage
=====
    ruco file.rb

Customize
=========

    # ~/.ruco.rb
    Ruco.configure do
      # bind a key, you can use Integers and Symbols
      # use "ruco --debug-keys foo" to see which keys are possible
      # or have a look at lib/ruco/keyboard.rb
      bind(:"Ctrl+e") do
        ask('delete ?') do |response|
          if response or not response
            editor.move(:to, 0, 0)
            editor.delete(9999)
          end
        end
      end

      # bind an existing action
      puts @actions.keys

      bind(:"Ctrl+x", :quit)
      bind(:"Ctrl+o", :save)
      bind(:"Ctrl+k", :delete_line)

      # define a new action and bind it to multiple keys
      action(:first){ editor.move(:to_column, 0) }
      bind(:"Ctrl+a", :first)
      bind(:home, :first)
    end

TIPS
====
 - [Ruby1.9] Unicode support -> install libncursesw5-dev before installing ruby (does not work for 1.8)

TODO
=====
 - session storage (stay at same line/column when reopening)
 - paste detection ? (ctrl+shift+insert / Cmd+v) -> no indentation
 - selecting -> delete / overwrite / copy / cut
 - smart staying at end of line/column when changing line
 - warnings / messages
 - syntax highlighting
 - support more key-combos/codes in keyboard.rb
 - raise when binding to a unsupported key
 - search & replace
 - 1.8: unicode support <-> already finished but usable due to Curses (see encoding branch)

Author
======
[Michael Grosser](http://grosser.it)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...
