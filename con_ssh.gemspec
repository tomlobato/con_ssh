Gem::Specification.new do |s|
  s.name          = "con_ssh"
  s.version       = "0.0.8"
  s.authors       = ["Tom Lobato"]
  s.email         = "lobato@bettercall.io"
  s.homepage      = "https://tomlobato.github.io/con_ssh/"
  s.summary       = "SSH cli wrapper."
  s.description   = "#{s.summary}."
  s.licenses      = ["MIT"]
  s.platform      = Gem::Platform::RUBY

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ["lib"]
  s.executables   = %w(con)
  s.required_ruby_version = '>= 2.0.0'
end

