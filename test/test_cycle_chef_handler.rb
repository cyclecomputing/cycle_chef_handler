require "test/unit"
require "cycle_chef_handler"

class TestCycleChefHandler < Test::Unit::TestCase
  
  def setup
    @index_file = File.join(File.dirname(__FILE__), 'index')
    @handler = CycleChefHandler.new(:amqp_config => {:host=> 'h'},
                                    :converge_index_file => @index_file )
  end

  def teardown
    File.unlink @index_file if File.exist? @index_file
  end

  def test_increment
    assert_equal(1, @handler.increment_count_file(@index_file))
    assert_equal(2, @handler.increment_count_file(@index_file))
  end

  def test_reset
    assert_equal(1, @handler.increment_count_file(@index_file))
    assert_equal(2, @handler.increment_count_file(@index_file))
    @handler.clear_count_file(@index_file)
    assert_equal(1, @handler.increment_count_file(@index_file))
  end
end
