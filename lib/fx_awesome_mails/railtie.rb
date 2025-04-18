require 'fx_awesome_mails/email_dsl'
module FXAwesomeMails
  class Railtie < ::Rails::Railtie
    initializer "fx_awesome_mails.email_dsl" do
      # ActiveSupport.on_load(:action_view) { include FXAwesomeMails::EmailHelpers }
      ActiveSupport.on_load(:action_view) { include FXAwesomeMails::EmailDSL }
    end
  end
end