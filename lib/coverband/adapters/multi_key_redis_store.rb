# frozen_string_literal: true

module Coverband
  module Adapters
    class MultiKeyRedisStore < Base
      ###
      # This key isn't related to the coverband version, but to the interal format
      # used to store data to redis. It is changed only when breaking changes to our
      # redis format are required.
      ###
      REDIS_STORAGE_FORMAT_VERSION = 'coverband_3_2'

      def initialize(redis, opts = {})
        super()
        @redis_namespace = opts[:redis_namespace]
        @format_version  = REDIS_STORAGE_FORMAT_VERSION
        @redis = redis
      end

      def clear!; end

      def save_report(report)
        expand_report(report).each do |file, data|
          @redis.set(key(file), data.to_json)
        end
      end

      def coverage
        @redis.keys(list_keys_value).each_with_object({}) do |key, coverage|
          coverage[key.gsub(key_prefix_substring, '')] = JSON.parse(@redis.get(key))
        end
      end

      private

      def key_prefix_substring
        "#{key_prefix}."
      end

      def key(file)
        [key_prefix, file].join('.')
      end

      def list_keys_value
        @list_keys_value ||= "#{key_prefix}.*"
      end

      def key_prefix
        @key_prefix ||= [@format_version, @redis_namespace].compact.join('.')
      end
    end
  end
end