require 'fast_spec_helper'
require 'lib/job_queue'

describe JobQueue do
  describe '.push' do
    it 'enqueues a Resque job' do
      job_class = double(:job_class)
      allow(Resque).to receive(:enqueue)

      JobQueue.push(job_class, 1, 2, 3)

      expect(Resque).to have_received(:enqueue).with(job_class, 1, 2, 3)
    end

    it 'returns true' do
      job_class = double(:job_class)
      allow(Resque).to receive(:enqueue)

      returned_value = JobQueue.push(job_class, 1, 2, 3)

      expect(returned_value).to be_truthy
    end
  end
end
