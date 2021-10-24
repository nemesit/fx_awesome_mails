module MailBag
  class Railtie < ::Rails::Railtie
    initializer "mail_bag.view_helpers" do
      ActiveSupport.on_load(:action_view) { include MailBag::EmailHelpers }
    end
  end
end

# module MailBag
#   module Rails
#     class Engine < ::Rails::Engine
#     end
#   end
# end