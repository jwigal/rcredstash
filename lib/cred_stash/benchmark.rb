module CredStash
  module Benchmark
    def benchmark(message = "Benchmarking")
      if defined?(Rails)
        result = nil
        ms = ::Benchmark.ms { result = yield }
        Rails.logger.info('CredStash / %s (%.1fms)' % [ message, ms ])
        result
      else
        yield
      end
    end
  end
end
