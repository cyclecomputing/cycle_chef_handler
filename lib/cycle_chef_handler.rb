# cycle_chef_handler.rb
#
# Report handler for chef clients to be used with CycleServer Chef Dashboard
#
# Author: Chris Chalfant (chris.chalfant@cyclecomputing.com)
# Author: Dan Harris (dharris@cyclecomputing.com)
#
# Copyright 2010 Cycle Computing LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rubygems'
require 'chef'
require 'bunny'
require 'classad'
require 'fileutils'
require 'uri'

class CycleChefHandler < Chef::Handler
  VERSION = '1.2.4'

  def initialize(params)
    defaults = {:exchange    => 'chef',
                :exchange_type => :direct,
                :exchange_durable => false,
                :exchange_autodelete => false,
                :bind_queue => false,
                :queue => nil,
                :queue_durable => false,
                :queue_autodelete => true,
                :routing_key => 'chef',
                :max_retries => 5,
                :retry_delay => 5}

    @amqp_config = defaults.merge(params[:amqp_config])
    check_amqp_config

    @extras = params[:extras] || {}
    @converge_index_file = params[:converge_index_file] || '/var/run/chef/converge_index'
    @failed_converge_file = params[:failed_converge_count_file] || '/var/run/chef/failed_converge_count'
  end

  def check_amqp_config
    [:host, :exchange].each do |i|
      if not @amqp_config[i]
        raise ArgumentError, ":amqp_config missing value for #{i}"
      end
    end
  end


  def report

    ## Create and Post a classad
    ad = create_ad
    payload = "<classads>" + ad.to_xml + "</classads>"
    
    for attempt in 1..@amqp_config[:max_retries] do
      begin

        b = Bunny.new(@amqp_config)

        b.start
        e = b.exchange(@amqp_config[:exchange], 
                      :type        => @amqp_config[:exchange_type],
                      :durable     => @amqp_config[:exchange_durable], 
                      :auto_delete => @amqp_config[:exchange_autodelete])

        # in some cases, the user may want to declare and bind a queue
        # to the exchange so consumers get all messages, even ones that 
        # enter the exchange before the consumer exists.
        if @amqp_config[:bind_queue]
          q = b.queue(@amqp_config[:queue], 
                     :durable     => @amqp_config[:queue_durable],
                     :auto_delete => @amqp_config[:queue_autodelete])

          if not @amqp_config[:routing_key].nil?

            q.bind(@amqp_config[:exchange], :key => @amqp_config[:routing_key])

          else

            q.bind(@amqp_config[:exchange])

          end

        end

        if not @amqp_config[:routing_key].nil?

          e.publish(payload, :key => @amqp_config[:routing_key])

        else
          
          e.publish(payload)
        
        end

        Chef::Log.info("Posted converge history report")
        return

      rescue Exception => e
        if attempt < @amqp_config[:max_retries]
          delay = attempt * @amqp_config[:retry_delay]
          Chef::Log.error("Failed to post converge history report, retrying in #{delay} seconds...")
          sleep(delay)  # Sleep for a while if it's a transient communcation error then try again
        else
          trace = e.backtrace.join("\n")
          Chef::Log.error("Failed to post converge history report: #{e.message} #{trace}")
          return
        end

      ensure

        b.stop

      end
    end
  end

  def create_ad
    ad = ClassAd.new
    ad['AdType']              = 'Chef.Host'
    ad['ChefNode']            = Chef::Config[:node_name]
    ad['ConvergeStartTime']   = start_time
    ad['ConvergeEndTime']     = end_time
    ad['ConvergeElapsedTime'] = RelativeTime.new(elapsed_time)

    updated = []
    if not updated_resources.nil?
      updated = updated_resources.map {|x| x.to_s}
    end

    ad['UpdatedResources']      = updated
    ad['UpdatedResourcesCount'] = updated.size
    ad['ConvergeIndex']         = increment_count_file(@converge_index_file)
    ad['ChefServerUrl']         = Chef::Config[:chef_server_url]
    ad['ChefServerHostName']    = URI.parse(Chef::Config[:chef_server_url]).host
    ad['ChefClientVersion']     = Chef::VERSION
    ad['CycleChefHandlerVersion'] = CycleChefHandler::VERSION
    ad['Success']               = success?

    exception = nil
    backtrace = nil
    if failed?
      exception = run_status.formatted_exception
      backtrace = run_status.backtrace
      ad['FailedConvergeCount'] = increment_count_file(@failed_converge_file)
    else
      clear_count_file(@failed_converge_file)
      ad['FailedConvergeCount'] = 0
    end

    ad['Exception']             = exception
    ad['Backtrace']             = backtrace

    @extras.each do |k,v|
      ad[k] = v
    end

    ad
  end

  def increment_count_file(count_file)
    file_dir = File.dirname(count_file)
    if not File.directory? file_dir
      FileUtils.mkdir_p file_dir
    end
   
    count = nil
    if File.exists? count_file
      File.open(count_file) do |file|
        count = file.readline.chomp.to_i
      end
    end

    if count.nil?
      count = 1
    else
      count += 1
    end

    File.open(count_file, "w") do |file|
      file.puts(count)
    end
      
    count
  end

  def clear_count_file(count_file)
    if File.exist? count_file
      FileUtils.rm count_file
    end
  end

end
