module CredStash
  module Benchmark
    def self.benchmark(message = "Benchmarking")
      if defined?(Rails)
        result = nil
        ms = Benchmark.ms { result = yield }
        Rails.logger.info('CredStash / %s (%.1fms)' % [ message, ms ])
        result
      else
        yield
      end
    end

    def benchmark(message = "Benchmarking")
      self.class.benchmark(message)
    end
  end
end
