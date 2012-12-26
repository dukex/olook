require 'em_test_helper'

class TestKeyboardEvents < Test::Unit::TestCase

  if !jruby?
    module KbHandler
      include EM::Protocols::LineText2
      def receive_line d
        EM::stop if d == "STOP"
      end
    end

    # This test doesn't actually do anything useful but is here to
    # illustrate the usage. If you removed the timer and ran this test
    # by itself on a console, and then typed into the console, it would
    # work.
    # I don't know how to get the test harness to simulate actual keystrokes.
    # When someone figures that out, then we can make this a real test.
    #
    def test_kb
      EM.run {
        EM.open_keyboard KbHandler
        EM::Timer.new(1) { EM.stop }
      } if $stdout.tty? # don't run the test unless it stands a chance of validity.
    end
  else
    warn "EM.open_keyboard not implemented, skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests
    def test_em_open_keyboard_unsupported
      assert true
    end
  end
end
