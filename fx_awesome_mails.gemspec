require_relative "lib/fx_awesome_mails/version"

Gem::Specification.new do |spec|
  spec.name        = "fx_awesome_mails"
  spec.version     = FXAwesomeMails::VERSION
  spec.authors     = ["Felix Gebhard"]
  spec.email       = ["fukurokujoe@googlemail.com"]
  spec.homepage    = "https://github.com/nemesit/fx_awesome_mails"
  spec.summary     = "Provides various view helpers for cross client mail creation"
  spec.description = "Provides various view helpers for cross client mail creation"
  spec.license     = ""

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/nemesit/fx_awesome_mails"
  spec.metadata["changelog_uri"] = "https://github.com/nemesit/fx_awesome_mails/blob/master/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 6.1.0"
end
