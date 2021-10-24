require_relative "lib/mail_bag/version"

Gem::Specification.new do |spec|
  spec.name        = "mail_bag"
  spec.version     = MailBag::VERSION
  spec.authors     = ["Felix Gebhard"]
  spec.email       = ["fukurokujoe@googlemail.com"]
  spec.homepage    = "https://github.com/nemesit/mail_bag"
  spec.summary     = "Provides various view helpers for cross client mail creation"
  spec.description = "Provides various view helpers for cross client mail creation"
  spec.license     = ""

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/nemesit/mail_bag"
  spec.metadata["changelog_uri"] = ""

  spec.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.4", ">= 6.1.4.1"
end
