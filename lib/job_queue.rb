require 'resque'

class JobQueue
  def self.push(job_class, *args)
    Resque.enqueue(job_class, *args)
    true
  end
end
