Gem::Specification.new do |s|
  s.name        = 'cycle_chef_handler'
  s.version     = '1.2.3'
  s.summary     = 'Chef report handling for CycleServer'
  s.description = %Q(This extension of Chef::Handler creates reports in
                     Condor class ad format and posts them to an amqp-compliant
                     message broker. This report handler was created to produce
                     reports for the CycleServer Chef Dashboard available from
                     Cycle Computing LLC.)
  s.authors     = ['Cycle Computing, LLC']
  s.email       = 'engineering@cyclecomputing.com'
  s.files       = ['lib/cycle_chef_handler.rb']
  s.homepage    = 'https://github.com/cyclecomputing/cycle_chef_handler'
  s.add_runtime_dependency 'bunny'
  s.add_runtime_dependency 'classad'
end
