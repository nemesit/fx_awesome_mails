require 'fx_awesome_mails/view_helpers'
module FXAwesomeMails
  class Railtie < ::Rails::Railtie
    initializer "fx_awesome_mails.view_helpers" do
      ActiveSupport.on_load(:action_view) { include FXAwesomeMails::EmailHelpers }
    end
  end
end

# module FXAwesomeMails
#   module Rails
#     class Engine < ::Rails::Engine
#     end
#   end
# end