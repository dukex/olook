require 'spec_helper'
require 'will_paginate/active_record'
require File.expand_path('../activerecord_test_connector', __FILE__)

ActiverecordTestConnector.setup
abort unless ActiverecordTestConnector.able_to_connect

describe WillPaginate::ActiveRecord do
  
  extend ActiverecordTestConnector::FixtureSetup
  
  fixtures :topics, :replies, :users, :projects, :developers_projects
  
  it "should integrate with ActiveRecord::Base" do
    ActiveRecord::Base.should respond_to(:paginate)
  end
  
  it "should paginate" do
    lambda {
      users = User.paginate(:page => 1, :per_page => 5).to_a
      users.length.should == 5
    }.should run_queries(2)
  end
  
  it "should fail when encountering unknown params" do
    lambda {
      User.paginate :foo => 'bar', :page => 1, :per_page => 4
    }.should raise_error(ArgumentError)
  end

  describe "relation" do
    it "should return a relation" do
      rel = nil
      lambda {
        rel = Developer.paginate(:page => 1)
        rel.per_page.should == 10
        rel.current_page.should == 1
      }.should run_queries(0)

      lambda {
        rel.total_pages.should == 2
      }.should run_queries(1)
    end

    it "should keep per-class per_page number" do
      rel = Developer.order('id').paginate(:page => 1)
      rel.per_page.should == 10
    end

    it "should be able to change per_page number" do
      rel = Developer.order('id').paginate(:page => 1).limit(5)
      rel.per_page.should == 5
    end

    it "remembers pagination in sub-relations" do
      rel = Topic.paginate(:page => 2, :per_page => 3)
      lambda {
        rel.total_entries.should == 4
      }.should run_queries(1)
      rel = rel.mentions_activerecord
      rel.current_page.should == 2
      rel.per_page.should == 3
      lambda {
        rel.total_entries.should == 1
      }.should run_queries(1)
    end

    it "supports the page() method" do
      rel = Developer.page('1').order('id')
      rel.current_page.should == 1
      rel.per_page.should == 10
      rel.offset.should == 0

      rel = rel.limit(5).page(2)
      rel.per_page.should == 5
      rel.offset.should == 5
    end

    it "raises on invalid page number" do
      lambda {
        Developer.page('foo')
      }.should raise_error(ArgumentError)
    end

    it "supports first limit() then page()" do
      rel = Developer.limit(3).page(3)
      rel.offset.should == 6
    end

    it "supports first page() then limit()" do
      rel = Developer.page(3).limit(3)
      rel.offset.should == 6
    end

    it "keeps pagination data after 'scoped'" do
      rel = Developer.page(2).scoped
      rel.per_page.should == 10
      rel.offset.should == 10
      rel.current_page.should == 2
    end
  end

  describe "counting" do
    it "should guess the total count" do
      lambda {
        topics = Topic.paginate :page => 2, :per_page => 3
        topics.total_entries.should == 4
      }.should run_queries(1)
    end

    it "should guess that there are no records" do
      lambda {
        topics = Topic.where(:project_id => 999).paginate :page => 1, :per_page => 3
        topics.total_entries.should == 0
      }.should run_queries(1)
    end

    it "forgets count in sub-relations" do
      lambda {
        topics = Topic.paginate :page => 1, :per_page => 3
        topics.total_entries.should == 4
        topics.where('1 = 1').total_entries.should == 4
      }.should run_queries(2)
    end

    it "remembers custom count options in sub-relations" do
      topics = Topic.paginate :page => 1, :per_page => 3, :count => {:conditions => "title LIKE '%futurama%'"}
      topics.total_entries.should == 1
      topics.length.should == 3
      lambda {
        topics.order('id').total_entries.should == 1
      }.should run_queries(1)
    end

    it "supports empty? method" do
      topics = Topic.paginate :page => 1, :per_page => 3
      lambda {
        topics.should_not be_empty
      }.should run_queries(1)
    end
    
    it "support empty? for grouped queries" do
      topics = Topic.group(:project_id).paginate :page => 1, :per_page => 3
      lambda {
        topics.should_not be_empty
      }.should run_queries(1)
    end

    it "supports `size` for grouped queries" do
      topics = Topic.group(:project_id).paginate :page => 1, :per_page => 3
      lambda {
        topics.size.should == {nil=>2, 1=>2}
      }.should run_queries(1)
    end

    it "overrides total_entries count with a fixed value" do
      lambda {
        topics = Topic.paginate :page => 1, :per_page => 3, :total_entries => 999
        topics.total_entries.should == 999
        # value is kept even in sub-relations
        topics.where('1 = 1').total_entries.should == 999
      }.should run_queries(0)
    end

    it "supports a non-int for total_entries" do
      topics = Topic.paginate :page => 1, :per_page => 3, :total_entries => "999"
      topics.total_entries.should == 999
    end

    it "removes :include for count" do
      lambda {
        developers = Developer.paginate(:page => 1, :per_page => 1).includes(:projects)
        developers.total_entries.should == 11
        $query_sql.last.should_not =~ /\bJOIN\b/
      }.should run_queries(1)
    end

    it "keeps :include for count when they are referenced in :conditions" do
      developers = Developer.paginate(:page => 1, :per_page => 1).includes(:projects)
      with_condition = developers.where('projects.id > 1')
      with_condition.total_entries.should == 1

      $query_sql.last.should =~ /\bJOIN\b/
    end

    it "should count with group" do
      Developer.group(:salary).page(1).total_entries.should == 4
    end

    it "should not have zero total_pages when the result set is empty" do
      Developer.where("1 = 2").page(1).total_pages.should == 1
    end
  end
  
  it "should not ignore :select parameter when it says DISTINCT" do
    users = User.select('DISTINCT salary').paginate :page => 2
    users.total_entries.should == 5
  end

  describe "paginate_by_sql" do
    it "should respond" do
      User.should respond_to(:paginate_by_sql)
    end

    it "should paginate" do
      lambda {
        sql = "select content from topics where content like '%futurama%'"
        topics = Topic.paginate_by_sql sql, :page => 1, :per_page => 1
        topics.total_entries.should == 1
        topics.first['title'].should be_nil
      }.should run_queries(2)
    end

    it "should respect total_entries setting" do
      lambda {
        sql = "select content from topics"
        topics = Topic.paginate_by_sql sql, :page => 1, :per_page => 1, :total_entries => 999
        topics.total_entries.should == 999
      }.should run_queries(1)
    end

    it "defaults to page 1" do
      sql = "select content from topics"
      topics = Topic.paginate_by_sql sql, :page => nil, :per_page => 1
      topics.current_page.should == 1
      topics.size.should == 1
    end

    it "should strip the order when counting" do
      lambda {
        sql = "select id, title, content from topics order by topics.title"
        topics = Topic.paginate_by_sql sql, :page => 1, :per_page => 2
        topics.first.should == topics(:ar)
      }.should run_queries(2)

      $query_sql.last.should include('COUNT')
      $query_sql.last.should_not include('order by topics.title')
    end

    it "shouldn't change the original query string" do
      query = 'select * from topics where 1 = 2'
      original_query = query.dup
      Topic.paginate_by_sql(query, :page => 1)
      query.should == original_query
    end
  end

  it "doesn't mangle options" do
    options = { :page => 1 }
    options.expects(:delete).never
    options_before = options.dup
    
    Topic.paginate(options)
    options.should == options_before
  end
  
  it "should get first page of Topics with a single query" do
    lambda {
      result = Topic.paginate :page => nil
      result.to_a # trigger loading of records
      result.current_page.should == 1
      result.total_pages.should == 1
      result.size.should == 4
    }.should run_queries(1)
  end
  
  it "should get second (inexistent) page of Topics, requiring 2 queries" do
    lambda {
      result = Topic.paginate :page => 2
      result.total_pages.should == 1
      result.should be_empty
    }.should run_queries(2)
  end
  
  it "should paginate with :order" do
    result = Topic.paginate :page => 1, :order => 'created_at DESC'
    result.should == topics(:futurama, :harvey_birdman, :rails, :ar).reverse
    result.total_pages.should == 1
  end
  
  it "should paginate with :conditions" do
    result = Topic.paginate :page => 1, :order => 'id ASC',
      :conditions => ["created_at > ?", 30.minutes.ago]
    result.should == topics(:rails, :ar)
    result.total_pages.should == 1
  end

  it "should paginate with :include and :conditions" do
    result = Topic.paginate \
      :page     => 1, 
      :include  => :replies,  
      :conditions => "replies.content LIKE 'Bird%' ", 
      :per_page => 10

    expected = Topic.find :all, 
      :include => 'replies', 
      :conditions => "replies.content LIKE 'Bird%' ", 
      :limit   => 10

    result.should == expected
    result.total_entries.should == 1
  end

  it "should paginate with :include and :order" do
    result = nil
    lambda {
      result = Topic.paginate(:page => 1, :include => :replies, :per_page => 10,
        :order => 'replies.created_at asc, topics.created_at asc').to_a
    }.should run_queries(2)

    expected = Topic.find :all, 
      :include => 'replies', 
      :order   => 'replies.created_at asc, topics.created_at asc', 
      :limit   => 10

    result.should == expected
    result.total_entries.should == 4
  end
  
  describe "associations" do
    it "should paginate with include" do
      project = projects(:active_record)

      result = project.topics.paginate \
        :page       => 1, 
        :include    => :replies,  
        :conditions => ["replies.content LIKE ?", 'Nice%'],
        :per_page   => 10

      expected = Topic.find :all, 
        :include    => 'replies', 
        :conditions => ["project_id = ? AND replies.content LIKE ?", project.id, 'Nice%'],
        :limit      => 10

      result.should == expected
    end

    it "should paginate" do
      dhh = users(:david)
      expected_name_ordered = projects(:action_controller, :active_record)
      expected_id_ordered   = projects(:active_record, :action_controller)

      lambda {
        # with association-specified order
        result = ignore_deprecation { dhh.projects.paginate(:page => 1) }
        result.should == expected_name_ordered
        result.total_entries.should == 2
      }.should run_queries(2)

      # with explicit order
      result = dhh.projects.paginate(:page => 1).reorder('projects.id')
      result.should == expected_id_ordered
      result.total_entries.should == 2

      lambda {
        dhh.projects.find(:all, :order => 'projects.id', :limit => 4)
      }.should_not raise_error
      
      result = dhh.projects.paginate(:page => 1, :per_page => 4).reorder('projects.id')
      result.should == expected_id_ordered

      # has_many with implicit order
      topic = Topic.find(1)
      expected = replies(:spam, :witty_retort)
      # FIXME: wow, this is ugly
      topic.replies.paginate(:page => 1).map(&:id).sort.should == expected.map(&:id).sort
      topic.replies.paginate(:page => 1).reorder('replies.id ASC').should == expected.reverse
    end

    it "should paginate through association extension" do
      project = Project.find(:first)
      expected = [replies(:brave)]

      lambda {
        result = project.replies.only_recent.paginate(:page => 1)
        result.should == expected
      }.should run_queries(1)
    end
  end
  
  it "should paginate with joins" do
    result = nil
    join_sql = 'LEFT JOIN developers_projects ON users.id = developers_projects.developer_id'

    lambda {
      result = Developer.paginate(:page => 1, :joins => join_sql, :conditions => 'project_id = 1')
      result.to_a # trigger loading of records
      result.size.should == 2
      developer_names = result.map(&:name)
      developer_names.should include('David')
      developer_names.should include('Jamis')
    }.should run_queries(1)

    lambda {
      expected = result.to_a
      result = Developer.paginate(:page => 1, :joins => join_sql,
        :conditions => 'project_id = 1', :count => { :select => "users.id" }).to_a
      result.should == expected
      result.total_entries.should == 2
    }.should run_queries(1)
  end

  it "should paginate with group" do
    result = nil
    lambda {
      result = Developer.paginate(:page => 1, :per_page => 10,
        :group => 'salary', :select => 'salary', :order => 'salary').to_a
    }.should run_queries(1)

    expected = users(:david, :jamis, :dev_10, :poor_jamis).map(&:salary).sort
    result.map(&:salary).should == expected
  end

  it "should not paginate with dynamic finder" do
    lambda {
      Developer.paginate_by_salary(100000, :page => 1, :per_page => 5)
    }.should raise_error(NoMethodError)
  end

  it "should paginate with_scope" do
    result = Developer.with_poor_ones { Developer.paginate :page => 1 }
    result.size.should == 2
    result.total_entries.should == 2
  end

  describe "scopes" do
    it "should paginate" do
      result = Developer.poor.paginate :page => 1, :per_page => 1
      result.size.should == 1
      result.total_entries.should == 2
    end

    it "should paginate on habtm association" do
      project = projects(:active_record)
      lambda {
        result = ignore_deprecation { project.developers.poor.paginate :page => 1, :per_page => 1 }
        result.size.should == 1
        result.total_entries.should == 1
      }.should run_queries(2)
    end

    it "should paginate on hmt association" do
      project = projects(:active_record)
      expected = [replies(:brave)]

      lambda {
        result = project.replies.recent.paginate :page => 1, :per_page => 1
        result.should == expected
        result.total_entries.should == 1
      }.should run_queries(2)
    end

    it "should paginate on has_many association" do
      project = projects(:active_record)
      expected = [topics(:ar)]

      lambda {
        result = project.topics.mentions_activerecord.paginate :page => 1, :per_page => 1
        result.should == expected
        result.total_entries.should == 1
      }.should run_queries(2)
    end
  end

  it "should paginate with :readonly option" do
    lambda {
      Developer.paginate :readonly => true, :page => 1
    }.should_not raise_error
  end
  
  it "should not paginate an array of IDs" do
    lambda {
      Developer.paginate((1..8).to_a, :per_page => 3, :page => 2, :order => 'id')
    }.should raise_error(ArgumentError)
  end

  it "errors out for invalid values" do |variable|
    lambda {
      # page that results in an offset larger than BIGINT
      Project.page(307445734561825862)
    }.should raise_error(WillPaginate::InvalidPage, "invalid offset: 9223372036854775830")
  end
  
  protected
  
    def ignore_deprecation
      ActiveSupport::Deprecation.silence { yield }
    end

    def run_queries(num)
      QueryCountMatcher.new(num)
    end

    def show_queries(&block)
      counter = QueryCountMatcher.new(nil)
      counter.run block
    ensure
      queries = counter.performed_queries
      if queries.any?
        puts queries
      else
        puts "no queries"
      end
    end

end

class QueryCountMatcher
  def initialize(num)
    @expected_count = num
  end

  def matches?(block)
    run(block)

    if @expected_count.respond_to? :include?
      @expected_count.include? @count
    else
      @count == @expected_count
    end
  end

  def run(block)
    $query_count = 0
    $query_sql = []
    block.call
  ensure
    @queries = $query_sql.dup
    @count = $query_count
  end

  def performed_queries
    @queries
  end

  def failure_message
    "expected #{@expected_count} queries, got #{@count}\n#{@queries.join("\n")}"
  end

  def negative_failure_message
    "expected query count not to be #{@expected_count}"
  end
end
