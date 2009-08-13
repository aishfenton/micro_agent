Gem::Specification.new do |s|
  s.name = "micro_agent"
  s.version = '0.1.5'
  s.authors = ["VisFleet"]
  s.homepage = ["labs.visfleet.com/micro_agent"]
  s.date = '2009-03-01'
  s.email = "lab-info@visfleet.com"
  s.files = [
             "lib/micro_agent.rb",
             "README.rdoc",
             "spec/micro_agent_spec.rb"
            ]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.require_paths = ["lib"]
  s.description = "A simple simulator"
  s.summary = <<-EOF
    A simple simulator. This gem simulates changes to a collection of agents over a period
    of time.
  EOF
end