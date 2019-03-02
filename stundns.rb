#!/usr/bin/env ruby
# vim: ai ts=2 sts=2 et sw=2 ft=ruby

require 'rubygems'
require 'rubydns'
require 'optparse'
require 'ipaddr'

module STUNDNS
  IN = Resolv::DNS::Resource::IN
 
  class STUNDNS

    def main
      @query_ip_report = ["stundns.internal"]
      @query_ip_port_report = ["stundns.internal"]
      @interfaces = [
        [:udp, "0.0.0.0", 5300],
        [:tcp, "0.0.0.0", 5300],
      ]
      parse_options!
      listen_server
    end

    def parse_options!
      @argv = ARGV.dup
      listen = []
      query_ip_report = []
      query_ip_port_report = []

      opt = OptionParser.new
      opt.on('-l LISTENIP[:PORT[/(udp/tcp)]]', "Listen IP:Port/Protocol (default: 0.0.0.0:5300)") {|v| listen.push(v) }
      opt.on('-a RECORD', "FQDN(or /Regex/) to respond the A/AAAA record. (default: #{@query_ip_report.join(",")})") {|v| query_ip_report.push(v) }
      opt.on('-t RECORD', "FQDN(or /Regex/) to respond the TXT record. (default: #{@query_ip_port_report.join(",")})") {|v| query_ip_port_report.push(v) }
      opt.parse!(@argv)

      @interfaces = parse_listen_option(listen, @interfaces)
      @query_ip_report = parse_record_option(query_ip_report, @query_ip_report)
      @query_ip_port_report = parse_record_option(query_ip_port_report, @query_ip_port_report)
    end

    def parse_record_option(records, default_records = [])
      result = default_records

      if records.length > 0
        result = []
        records.each do |r|
          if r =~ /^\/(.*)\/$/
            regex = $1
            result.push(Regexp.new(regex))
          else
            result.push(r)
          end
        end
      end

      return result
    end

    def parse_listen_option(listen, default_interfaces = [])
      interfaces = default_interfaces

      if listen.length > 0
        interfaces = []
        listen.each do |l|
          if l =~ /^(.*?)(:(\d+))?(\/(tcp|udp))?$/
            protos = [:udp, :tcp]
            ip = $1
            port = $3
            proto = $5

            # ipv5
            if ip =~ /^\[(.*)\]$/
              ip = $1
            end

            unless proto.nil?
              protos = [proto.to_sym]
            end

            protos.each do |pr|
              interfaces.push([
                pr, ip, port
              ])
            end
          end
        end
      end

      return interfaces
    end

    def respond_your_ip(server, transaction)
      begin
        ip_str = transaction.options[:peer]
        ip = IPAddr.new(ip_str)
        if ip.ipv4?
          transaction.respond!(ip.to_s, {:ttl => 0, :resource_class => IN::A})
        elsif ip.ipv4_mapped?
          transaction.respond!(ip.native.to_s, {:ttl => 0, :resource_class => IN::A})
        elsif ip.ipv6?
          transaction.respond!(ip.to_s, {:ttl => 0, :resource_class => IN::AAAA})
        else
          transaction.fail!(:ServFail)
        end
      rescue => error
        server.logger.log(Logger::ERROR, error.to_s)
        transaction.fail!(:ServFail)
      end
    end

    def respond_your_ip_port(server, transaction)
      begin
        ip_address = transaction.options[:peer]
        port = transaction.options[:port]
        txt_response = "%s %d" % [ip_address, port]
        transaction.respond!(txt_response, {:ttl => 0})
      rescue => error
        transaction.fail!(:ServFail)
      end
    end

    def listen_server
      # RubyDNS::run_server ブロック内では self が変わるので
      # ローカル変数経由で渡す
      query_ip_report = @query_ip_report
      query_ip_port_report = @query_ip_port_report
      stundns = self

      RubyDNS::run_server({:listen =>@interfaces}) do
        query_ip_report.each do |q|
          match(q, [IN::A, IN::AAAA]) do |transaction|
            stundns.respond_your_ip(self, transaction)
          end
        end

        query_ip_port_report.each do |q|
          match(q, IN::TXT) do |transaction|
            stundns.respond_your_ip_port(self, transaction)
          end
        end
      
        otherwise do |transaction|
          transaction.fail!(:NXDomain)
        end
      end
    end
  end

end

if __FILE__ == $0
  STUNDNS::STUNDNS.new.main
end
