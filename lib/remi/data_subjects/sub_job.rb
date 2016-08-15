module Remi
  class Extractor::SubJob < Extractor

    # @param sub_job [Object] The name (relative to parent job) of the subjob to use
    # @param data_subject [Symbol] The name (relatvie to the sub job) of the sub job's data frame
    def initialize(*args, **kargs, &block)
      super
      init_sub_job_extractor(*args, **kargs, &block)
    end

    attr_accessor :sub_job, :data_subject

    def extract
      sub_job.job.send(data_subject).df
    end

    private

    def init_sub_job_extractor(*args, sub_job:, data_subject:, **kargs, &block)
      @sub_job = sub_job
      @data_subject = data_subject
    end

  end

  class Loader::SubJob < Loader
    # @param sub_job [Object] The name (relative to parent job) of the subjob to use
    # @param data_subject [Symbol] The name (relatvie to the sub job) of the sub job's data frame
    def initialize(*args, **kargs, &block)
      super
      init_sub_job_loader(*args, **kargs, &block)
    end

    attr_accessor :sub_job, :data_subject

    # @param data_frame [Object] Data frame to load to target sub job data subject
    # @return [true] On success
    def load(data_frame)
      sub_job.job.send(data_subject).df = data_frame
      true
    end

    private

    def init_sub_job_loader(*args, sub_job:, data_subject:, **kargs, &block)
      @sub_job = sub_job
      @data_subject = data_subject
    end
  end
end
