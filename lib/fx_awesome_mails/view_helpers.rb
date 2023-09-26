require 'fx_awesome_mails/refinements'
module FXAwesomeMails
  module EmailHelpers

    using FXAwesomeMails::Refinements

    def preheader(text)
      "<div style='display: none; max-height: 0px; overflow: hidden;'>
        #{text}
      </div>
      <div class='preheader' style='display: none; width: 0px; height: 0px; max-height: 0px; overflow: hidden;'>
        &#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;
      </div>".html_safe
    end

    def titlebar_link(link)
      "<div class='tac pt10 pb10 pl5 pr5'>
        <!--[if gte mso 12]><br><![endif]-->
          #{link}
        <!--[if gte mso 12]><br><![endif]-->
      </div>".html_safe
    end

    def divider(options = {})
      "<p class='MsoNormal'><o:p>&nbsp;</o:p></p>".html_safe # TODO: options/smaller
    end

    # experimental mail helpers
    def content_tag_if(condition, name, content_or_options_with_block = {}, options = {}, escape = true, &block)
      options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash) if block_given?
      options.each do |option, values|      
        options[option] = case values
          when Array then values.send(condition ? "first" : "last")
          when Hash then ((values[:if] && values[:else]) ? values[(condition ? :if : :else)] : values.to_s)
          else values.to_s
        end
      end
      content_or_options_with_block, options = options, nil if block_given?
      content_tag(name, content_or_options_with_block, options, escape, &block)   
    end

    def rounded_box(&block)
      html = "<div class='rounded_box'><div class='rounded_box_content'><div class='rounded_box_top'></div>"        
      html << capture(:foo, :bar, &block)
      html << "<div class='rounded_box_bottom'><div></div></div></div>"
      raw html
    end

    # https://edgeapi.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to_if + link_to( ...&block)
    def link_to_if_true(condition, name, options = {}, html_options = {}, &block)
      if condition
        link_to(name, options, html_options, &block)
      else
        if block_given?
          block.arity <= 1 ? capture(name, &block) : capture(name, options, html_options, &block)
        else
          ERB::Util.html_escape(name)
        end
      end
    end

    class Button
      attr_accessor :parent
      def initialize(parent)
        self.parent = parent
      end
      delegate :capture, :content_tag, :link_to, :link_to_if, :link_to_if_true, :image_tag, :to => :parent

      # simple, graphical
      def simple_button(text = nil, type: :simple, **options, &block)
        html = "<th valign='bottom' style='text-align:left' class='buttoncellclass mobile-display-block button-container' bgcolor='#000000'>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='width:100% !important' role='presentation'>
            <tbody>
              <tr>
                <th valign='top'>
                  <table cellpadding='0' cellspacing='0' border='0' width='auto' style='margin:0 auto' role='presentation' align='center'>
                    <tbody>
                      <tr>"

                        # style = mso-line-height-rule: exactly; -webkit-border-radius:10px;-moz-border-radius:10px;border-radius:10px;background:#FFFF00;text-align:right
                        # link_style = -webkit-border-radius: 10px; -moz-border-radius: 10px; border-radius: 10px; padding: 10px 20px; display: inline-block; text-decoration: none; text-align: right; color: #00FF00; border: 12; font-family: Arial, sans-serif; font-size: 13px; line-height: 14px; font-weight: 500;
        html << content_tag('th', valign: options[:valign].to_s, align: options[:align].to_s) do
          link_to_if_true(options[:link_to_url].present?, options[:link_to_url].presence, target: '_blank') do
            "#{block_given? ? capture(&block) : text}".html_safe
          end
        end

        html <<       "</tr>
                    </tbody>
                  </table>
                </th>
              </tr>
            </tbody>
          </table>
        </th>"

        html.html_safe
      end

      def graphical_button(text, type: :simple, **options, &block)
        "<th valign='bottom' style='text-align:left' class='buttoncellclass mobile-display-block button-container' bgcolor='#000000'>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='width:100% !important' role='presentation'>
            <tbody>
              <tr>

                

              </tr>
            </tbody>
          </table>
        </th>"
      end

      def button(text = nil, type: :simple, **options)
        case type
        when :simple
          simple_button(text, **options)
        when :graphical
          graphical_button(text, **options)
        end
      end
    end

    class Spacer
      attr_accessor :parent

      def initialize(parent)
        self.parent = parent
      end
      delegate :capture, :content_tag, :link_to, :link_to_if, :link_to_if_true, :image_tag, :to => :parent

      def horizontal(height = '20', **options)
        options = {valign: 'top', class: '',style: "text-align:left;font-size:1px;line-height:1px"}.merge_email_options(options)
        content_tag('th', '&nbsp;'.html_safe, height: height, valign: "#{options[:valign]}", style: "#{options[:style]}", class: "#{options[:class]} horizontal-spacer horizontal-gutter", bgcolor: options[:style].to_s.to_css_hash["background-color"].try(&:to_s))
      end

      def vertical(width = '20', **options)
        options = {valign: 'top', class: '',style: "text-align:left;font-size:1px;line-height:1px"}.merge_email_options(options)
        content_tag('th', '&nbsp;'.html_safe, width: width, valign: "#{options[:valign]}", style: "#{options[:style]}", class: "#{options[:class]} vertical-spacer vertical-gutter", bgcolor: options[:style].to_s.to_css_hash["background-color"].try(&:to_s))
      end
    end

    Gutter = Spacer

    class Text
      attr_accessor :parent
      def initialize(parent)
        self.parent = parent
      end
      delegate :capture, :content_tag, :link_to, :link_to_if, :link_to_if_true, :image_tag, :to => :parent

      def text(text = nil, **options, &block)
        options = {valign: "top", style: "mso-line-height-rule:exactly;text-align:left;font-weight:400"}.merge_email_options(options)      
        content_tag('th', valign: "#{options[:valign]}", style: options[:style], class: "#{options[:class]} text-container", bgcolor: options[:style].to_s.to_css_hash["background-color"].presence.try(&:to_s)) do
          "#{block_given? ? capture(&block) : text}".html_safe
        end
      end
    end

    class Image
      attr_accessor :parent
      def initialize(parent)
        self.parent = parent
      end
      delegate :capture, :content_tag, :link_to, :link_to_if, :link_to_if_true, :image_tag, :to => :parent

      def email_image_tag(source: nil, **options, &block)
        options = {alt: '', link_url: nil, width: 130, height: 50, valign: 'top', align: 'left', class: '', style: "background-color: transparent;outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; display: block; border: none" }.merge_email_options(options)
        html = "<th valign='#{options[:valign]}' style='text-align:#{options[:align]}' class='#{options[:class]} image-container' bgcolor='#{options[:style].to_s.to_css_hash["background-color"]}' align='#{options[:align]}'>"
        html << link_to_if_true(options[:link_url].present?, options[:link_url], target: '_blank') do
          image_tag(source, style: options[:style], width: "#{options[:width]}", height: "#{options[:height]}", alt: "#{options[:alt]}")
        end
        html << "</th>"
        
        html.html_safe
      end
    end

    class VStack
      attr_accessor :parent
      def initialize(parent)
        self.parent = parent
      end
      delegate :capture, :content_tag, :link_to, :link_to_if, :link_to_if_true, :image_tag, :to => :parent

      def self.vstack(_capture_helper, **options, &block)
        options = { valign: 'top', style: "text-align: left" }.merge_email_options(options)
        _capture_helper.content_tag('th', valign: "#{options[:valign]}", style: "#{options[:style]}", class: "vertical-stack vertical-grid #{options[:class]}") do
          "<table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
            <tbody>
              #{_capture_helper.capture(VStack.new(_capture_helper), &block)}
            </tbody>
          </table>".html_safe
        end
      end

      def spacer(...)
        "<tr>#{Spacer.new(parent).horizontal(...)}</tr>".html_safe
      end

      def text(text = nil, **options, &block)
        "<tr>#{Text.new(parent).text(text, **options, &block)}</tr>".html_safe
      end

      def image(...)
        "<tr>#{Image.new(parent).email_image_tag(...)}</tr>".html_safe
      end

      def button(...)
        "<tr>
          #{Button.new(parent).button(...)}
        </tr>".html_safe
      end

      def hstack(**options, &block)
        "<tr>#{HStack.hstack(parent, **options, &block)}</tr>".html_safe
      end

      def vstack(**options, &block)
        "<tr>#{VStack.vstack(parent, **options, &block)}</tr>".html_safe
      end

      alias_method :horizontal_grid, :hstack
      alias_method :vertical_grid, :vstack
      alias_method :gutter, :spacer
      
      class <<self  
        alias_method :vertical_grid, :vstack
      end
    end

    VerticalGrid = VStack

    class HStack
      attr_accessor :parent
      def initialize(parent)
        self.parent = parent
      end
      delegate :capture, :content_tag, :link_to, :link_to_if, :link_to_if_true, :image_tag, :to => :parent

      def self.hstack(_capture_helper, **options, &block)
        options = { valign: 'top', style: "text-align: left" }.merge_email_options(options)
        "<th valign='#{options[:valign]}' style='#{options[:style]}' class='#{options[:class]} horizontal-stack horizontal-grid'>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
            <tbody>
              <tr>
                #{_capture_helper.capture(HStack.new(_capture_helper), &block)}
              </tr>
            </tbody>
          </table>
        </th>".html_safe
      end

      def spacer(...)
        "#{Spacer.new(parent).vertical(...)}".html_safe
      end

      def text(...)
        "#{Text.new(parent).text(...)}".html_safe
      end

      def image(...)
        "#{Image.new(parent).email_image_tag(...)}".html_safe
      end

      def button
        "<th valign='top' style='text-align:left' class='button-container'>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='width:100% !important' role='presentation'>
            <tbody>
              <tr>
                <th valign='top'>
                  <table cellpadding='0' cellspacing='0' border='0' width='auto' role='presentation' align='left'>
                    <tbody>
                      <tr>
                        <th valign='middle' style='mso-line-height-rule: exactly; -webkit-border-radius:4px;-moz-border-radius:4px;border-radius:4px;background:#444444;text-align:left' align='left'><a style='-webkit-border-radius: 4px; -moz-border-radius: 4px; border-radius: 4px; padding: 10px 20px; display: inline-block; text-decoration: none; text-align: left; color: #FFFFFF; border: 1px solid #444444; font-family: Arial, sans-serif; font-size: 15px; line-height: 18px; font-weight: normal;' href='#' target='_blank'>Click here</a></th>
                      </tr>
                    </tbody>
                  </table>
                </th>
              </tr>
            </tbody>
          </table>
        </th>".hmtl_safe
      end

      def hstack(**options, &block)
        "#{HStack.hstack(parent, **options, &block)}".html_safe
      end

      def vstack(**options, &block)
        "#{VStack.vstack(parent, **options, &block)}".html_safe
      end

      alias_method :horizontal_grid, :hstack
      alias_method :vertical_grid, :vstack
      alias_method :gutter, :spacer
      
      class <<self  
        alias_method :horizontal_grid, :hstack
      end
    end

    HorizontalGrid = HStack
    
    class EmailContent
      attr_accessor :parent
      def initialize(parent)
        self.parent = parent
      end
      delegate :capture, :content_tag, :link_to, :link_to_if, :link_to_if_true, :image_tag, :to => :parent

      def self.email_content(_capture_helper, **options, &block)
        options = {alt: '', link_url: nil, width: 600, height: 50, valign: 'top', align: 'left', class: '', background: '', style: "background-color: #FFFFFF" }.merge_email_options(options)
        "<table cellpadding='0' cellspacing='0' border='0' width='#{options[:width]}' style='margin: 0; padding: 0; text-align: left; width: 100%; min-width: 600px; line-height: 100%;' role='presentation' background='#{options[:background]}' class='background-table has-width-#{options[:width]}' bgcolor='#{options[:style].to_s.to_css_hash["background-color"]}' valign='top'>
          <tbody>
            <tr>
              <th valign='top'>
                <table cellpadding='0' cellspacing='0' border='0' width='#{options[:width]}' style='width:#{options[:width]}px;margin:0 auto' role='presentation' class='#{options[:class]} email-content' align='center'>
                  <tbody>
                    <tr>
                      <th valign='top'>
                        <div>
                          #{_capture_helper.capture(ContentTable.new(_capture_helper), &block)}
                        </div>
                      </th>
                    </tr>
                  </tbody>
                </table>
              </th>
            </tr>
          </tbody>
        </table>".html_safe
      end

      def text(...)
        "<div>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
            <tbody>
              <tr>
                #{Text.new(parent).text(...)}
              </tr>
            </tbody>
          </table>
        </div>".html_safe
      end
      
      def image(...)
        "<div>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
            <tbody>
              <tr>
              #{Image.new(parent).email_image_tag(...)}
              </tr>
            </tbody>
          </table>
        </div>".html_safe
      end

      def button
        "<div>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
            <tbody>
              <tr>

                <th valign='top' style='text-align:left' class='button-container'>
                  <table cellpadding='0' cellspacing='0' border='0' width='100%' style='width:100% !important' role='presentation'>
                    <tbody>
                      <tr>
                        <th valign='top'>
                          <table cellpadding='0' cellspacing='0' border='0' width='auto' role='presentation' align='left'>
                            <tbody>
                              <tr>
                                <th valign='middle' style='mso-line-height-rule: exactly; -webkit-border-radius:4px;-moz-border-radius:4px;border-radius:4px;background:#444444;text-align:left' align='left'><a style='-webkit-border-radius: 4px; -moz-border-radius: 4px; border-radius: 4px; padding: 10px 20px; display: inline-block; text-decoration: none; text-align: left; color: #FFFFFF; border: 1px solid #444444; font-family: Arial, sans-serif; font-size: 15px; line-height: 18px; font-weight: normal;' href='#' target='_blank'>Click here</a></th>
                              </tr>
                            </tbody>
                          </table>
                        </th>
                      </tr>
                    </tbody>
                  </table>
                </th>

              </tr>
            </tbody>
          </table>
        </div>".html_safe
      end

      def spacer(...)
        # only horizontal
        "<div>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
            <tbody>
              <tr>
                #{Spacer.new(parent).horizontal(...)}
              </tr>
            </tbody>
          </table>
        </div>".html_safe
      end

      def hstack(**options, &block)
        "<div>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
            <tbody>
              <tr>
                #{HStack.hstack(parent, **options, &block)}
              </tr>
            </tbody>
          </table>
        </div>".html_safe
      end

      def vstack(**options, &block)
        "<div>
          <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
            <tbody>
              <tr>
                #{VStack.vstack(parent, **options, &block)}
              </tr>
            </tbody>
          </table>
        </div>".html_safe
      end

      # def content(**options, &block)
      #   "<div>
      #     <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
      #       <tbody>
      #         <tr>
      #           #{capture(&block)}
      #         </tr>
      #       </tbody>
      #     </table>
      #   </div>".html_safe
      # end
      alias_method :horizontal_grid, :hstack
      alias_method :vertical_grid, :vstack
      alias_method :gutter, :spacer
      
      class <<self  
        alias_method :content_table, :email_content
      end
    end

    ContentTable = EmailContent

    def email_content(**options, &block)
      ContentTable.content_table(self, **options, &block)
    end

    alias_method :content_table, :email_content
  end
end