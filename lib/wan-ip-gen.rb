#!/usr/bin/env ruby
# frozen_string_literal: true

require 'socket'

module IP
  # WAN range IP generator
  #
  # Example:
  #   IP::RandomWAN.new.first(5)
  class RandomWAN
    include Enumerable

    RANGES = [
      (0xb000000..0x643fffff),
      (0x80000000..0xa9fdffff),
      (0x64800000..0x7effffff),
      (0xcb007200..0xdfffffff),
      (0xac200000..0xbfffffff),
      (0xc0a90000..0xc611ffff),
      (0xc6336500..0xcb0070ff),
      (0xa9ff0000..0xac0fffff),
      (0xc0000300..0xc05862ff),
      (0xc0586400..0xc0a7ffff),
      (0xc6140000..0xc63363ff),
      (0xc0000100..0xc00001ff)
    ].freeze

    SIZES = RANGES.map(&:size)
    TOTAL = SIZES.sum.to_f
    PROBABILITIES = SIZES.map { |s| s / TOTAL }

    def intip
      p = rand
      i = PROBABILITIES.index { |rp| p < rp || !(p -= rp) }
      rand RANGES[i]
    end

    def each(&block)
      loop do
        block.call [intip].pack('N').unpack('CCCC').join('.')
      end
    end

    def each_socket(port = 80, connect_timeout = 0.75)
      each do |ip|
        Socket.tcp(ip, port, connect_timeout: connect_timeout) do |s|
          yield(s, ip)
        end
      rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH
        next
      rescue Errno::ECONNRESET, Errno::ENOPROTOOPT
        next
      end
    end
  end
end

if $0 == __FILE__
  IP::RandomWAN.new.each do |ip|
    puts ip
  end
end
