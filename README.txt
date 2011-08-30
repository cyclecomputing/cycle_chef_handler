= cycle_chef_handler

* http://github.com/cyclecomputing/cycle_chef_handler
* http://www.cyclecomputing.com

== DESCRIPTION:

This extension of Chef::Handler creates reports in Condor class ad format and posts
them to an amqp-complient message broker. This report handler was created to produce
reports for the CycleServer Chef Dashboard available from Cycle Computing LLC.

== REQUIREMENTS:

* chef
* classad
* bunny

== INSTALL:

* sudo gem install cycle_chef_handler
* edit /etc/chef/client.rb on client nodes:

  require 'cycle_chef_handler'

  handler = CycleChefHandler.new(:amqp_config => {:host => 'my_amqp_hostname'})

  report_handlers    << handler
  exception_handlers << handler

== ADVANCED USAGE:

The constructor takes a hash with the following keys:

:amqp_config
This key should point to a configuration hash suitable for Bunny.new(), including:

* :host Host name of amqp broker
* :port Port of amqp borker, default value = 5672
* :vhost Name of virtual host on amqp broker, default value = '/'
* :user User name on amqp broker, default value = 'guest'
* :pass Password for :user on amqp broker, default value = 'guest'
* :queue Queue name to be used to read report messages, default value = 'chef.converges'
* :exchange Exchange name to be used to post report messages, default value = 'chef.converges'

:extras
This optional key may be used to pass arbitrary key, value pairs to the chef report classad.
It may be used to tag chef clients to make it easier to slice and dice the report information.
I use it (along with the ec2_metadata gem) to add Amazon Web Services EC2 instance data to
the report.

  :extras => {'InstanceId'       => Ec2Metadata[:instance_id],
              'AvailabilityZone' => Ec2Metadata[:placement][:availability_zone],
              'PublicHostName'   => Ec2Metadata[:public_hostname]}

:converge_index_file
This should point to a file where CycleChefHandler will keep track of the number of
converges that have been attempted. Its default value is /var/run/chef/converge_index.

:failed_converge_count_file
This should point to a file where CycleChefHandler will keep track of the number of 
consecutive failed converges. Its default value is /var/run/chef/failed_converge_count.

== DEVELOPERS:

After checking out the source, run:

  $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the RDoc.

== LICENSE:

Copyright 2011 Cycle Computing LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
