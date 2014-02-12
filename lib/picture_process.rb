class PictureProcess
  DIRECTORY = 'product_pictures'
  attr_accessor :params
  @queue = 'low'

  def self.list(options={})
    @@directory ||= self.connection
    @@directory.instance_variable_set('@files', nil)
    @@directory.files.all(delimiter: '/', prefix: options[:prefix]).common_prefixes
  end

  def self.perform(options={})
    self.new(options).perform
  end

  def self.is_pending?(*args)
    is_working?(*args) || is_in_queue?(*args) 
  end

  def initialize(options={})
    @key = options['key']
    raise ArgumentError.new("Directory to process on S3 Bucket is necessary (key is nil)") if @key.blank?
  end

  def perform
    hash = Hash.new
    arr = []
    files = self.class.directory.files.all(delimiter: '/', prefix: @key).common_prefixes
    files.map do |file|
      product_number = file.gsub(/\D/, '')
      arr = self.class.directory.files.all(delimiter: '/', prefix: file).map{|f| f.public_url}
      arr.shift
      arr
      hash[product_number] = arr 
      hash
    end
    binding.pry
    hash
    puts "Fazendo a porra toda"
    sleep 600
  end

  private
  def self.directory
    connection ||= Fog::Storage[:aws]
    connection.directories.get(DIRECTORY)
  end

  def self.is_in_queue?(*args)
    key = Resque.encode(class: self.to_s, args: args)
    queue = "queue:#{@queue}"
    jobs = Resque.redis.lrange(queue, 0, -1)
    jobs.any? do |job|
      job == key
    end
  end

  def self.is_working?(*args)
    key = Resque.decode(Resque.encode( class: self.to_s, args: args ))
    Resque.working.any? do |worker|
      worker.job['payload'] == key
    end
  end
end
