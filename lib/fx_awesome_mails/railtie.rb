require 'fx_awesome_mails/email_dsl'
module FXAwesomeMails
  class Railtie < ::Rails::Railtie
    initializer "fx_awesome_mails.email_dsl" do
      ActiveSupport.on_load(:action_view) { include FXAwesomeMails::DSL }
      ActiveSupport.on_load(:action_view) { ActionView::Helpers::TagBuilder.include FXAwesomeMails::HelperFunctions }
    end
  end
end