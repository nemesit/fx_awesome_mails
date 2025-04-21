require "action_view"
require "active_support"

module FXAwesomeMails

  module DSL

    class Current < ActiveSupport::CurrentAttributes
      attribute :view, :parent
    end

    module TagExtensions
      
      def vstack(...)
        VStack.new(...)
      end

      def hstack(...)
        HStack.new(...)
      end
      
      def zstack(...)
        ZStack.new(...)
      end
      
      def spacer(size = 16, **options)
        Spacer.new(size, **options)
      end
  
      def preheader(text = nil, **attrs)
        Preheader.new(text, **attrs)
      end
  
      def titlebar_link(link_html = nil, **attrs)
        TitlebarLink.new(link_htmls, **attrs)
      end
  
      def divider(...)
        Divider.new(...)
      end
  
      def image(...)
        Image.new(...)
      end
  
      def text(...)
        TextContent.new(...)
      end
  
      def layout_table(...)
        LayoutTable.new(...)
      end

      def item(...)
        Item.new(...)
      end

      # def zstack(...)
      #   ZStack.new(...)
      # end

      # def item(...)
      #   if DSL::Current.parent.is_a?(ZStacl)
      #     DSL::Current.parent.item(...)
      #   else
      #     Item.new(...)
      #   end
      # end

    end

    module Refinements
      refine String do
        def to_css_hash
          Hash[split(";").map { _1.split(":").map(&:strip) }]
        end
    
        def merge_css_options(second, key)
          return strip if second.blank?
          return second.strip if blank?
    
          case key
          when :style
            strip.to_css_hash
                .deep_merge_v2(second.strip.to_css_hash)
                .map { |k, v| "#{k}:#{v}" }
                .join(";")
          when :class
            strip.split(" ").union(second.strip.split(" ")).join(" ")
          else
            ""
          end
        end
      end
    
      refine Hash do
        def deep_merge_v2(second)
          merger = proc do |_, v1, v2|
            if v1.is_a?(Hash) && v2.is_a?(Hash)
              v1.merge(v2, &merger)
            elsif v1.is_a?(Array) && v2.is_a?(Array)
              v1 | v2
            elsif [:undefined, nil, :nil].include?(v2)
              v1
            else
              v2
            end
          end
          merge(second.to_h, &merger)
        end
    
        def merge_email_options(second)
          merger = proc do |k, v1, v2|
            if v1.is_a?(Hash) && v2.is_a?(Hash)
              v1.merge(v2, &merger)
            elsif v1.is_a?(Array) && v2.is_a?(Array)
              v1 | v2
            elsif [:undefined, nil, :nil].include?(v2)
              v1
            elsif [:style, :class].include?(k)
              v1.merge_css_options(v2, k)
            else
              v2
            end
          end
          merge(second.to_h, &merger)
        end
      end
    end

    using Refinements

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

    class Element
      include ActionView::Helpers::TagHelper
      include ActionView::Context
      delegate_missing_to :@view
      
      class_attribute :default_email_options, instance_predicate: false, default: {}
      class_attribute :non_overridable_email_options, instance_predicate: false, default: {}

      def initialize(**attrs, &block)
        view_ctx = attrs.delete(:view)    
        view_ctx ||= DSL::Current.view
        
        if view_ctx.nil? && block
          recv = block.respond_to?(:receiver) ? block.receiver : block.binding.receiver
          view_ctx = recv if recv.respond_to?(:capture) && recv.respond_to?(:content_tag)
        end
        
        unless view_ctx
          raise ArgumentError,
                "EmailDSL: cannot infer ActionView context. "\
                "Pass `view: view_context` to the first component."
        end
        
        DSL::Current.view = @view = view_ctx
        @attrs = attrs.compact
        @block = block
      end

      def email_options
        merged = default_email_options.merge_email_options(@attrs)
        merged = merged.merge(non_overridable_email_options)
        normalize_email_options(merged)
      end
      
      protected
      def capture_body
        prev = DSL::Current.parent
        DSL::Current.parent = self
        (@block ? @view.capture(self, &@block) : "")&.html_safe
      ensure
        DSL::Current.parent = prev
      end

      private
      def normalize_email_options(options)
        new_options = options.deep_dup
        new_options[:style]&.to_css_hash&.dig("background-color").try { new_options[:bgcolor] ||= _1 }
        new_options
      end

    end
    
    class Spacer < Element
      def initialize(size = 16, **a)
        super(size: size, **a)
      end
      
      self.default_email_options = { valign: "top", style: "font-size:0;line-height:0;mso-line-height-rule:exactly" }

      def to_s
        inside_vstack = DSL::Current.parent.is_a?(VStack)
        options = email_options
        options[inside_vstack ? :height : :width] ||= options.delete(:size) || 16
        options = options.merge_email_options({ class: inside_vstack ? "vstack_spacer" : "hstack_spacer" })
      
        if inside_vstack
          @view.content_tag("tr") do
            @view.content_tag('th', '&nbsp;'.html_safe, options)
          end
        else
          @view.content_tag('th', '&nbsp;'.html_safe, options)
        end
      end
    end
    
    class HStack < Element      
      self.default_email_options = { valign: 'top', style: "text-align: left", class: "hstack" }

      def initialize(**a)
        super(**a)
      end

      def to_s
        if DSL::Current.parent.is_a?(VStack)

          tag.tr do
            tag.th(email_options) do
              tag.table(cellpadding: "0", border: "0", width: "100%", style: "min-width:100%", role: "presentation") do
                tag.tbody do
                  tag.tr(capture_body)
                end
              end
            end
          end

        else

          tag.th(email_options) do
            tag.table(cellpadding: "0", cellspacing: "0", border: "0", width: "100%", style: "min-width:100%", role: "presentation") do
              tag.tbody do
                tag.tr(capture_body)
              end
            end
          end

        end
      end
    end
    
    class VStack < Element # Apply same logging to HStack
      self.default_email_options = { valign: 'top', style: "text-align: left", class: "vstack" }

      def initialize(**a)
        super(**a)
      end

      def to_s
        if DSL::Current.parent.is_a?(VStack)

          tag.tr do
            tag.th(email_options) do
              tag.table(cellpadding: '0', cellspacing: '0', border: '0', width: '100%', style: 'min-width:100%', role: 'presentation') do
                tag.tbody(capture_body)
              end
            end
          end

        else

          tag.th(email_options) do
            tag.table(cellpadding: '0', cellspacing: '0', border: '0', width: '100%', style: 'min-width:100%', role: 'presentation') do
              tag.tbody(capture_body)
            end
          end

        end
      end
    end

    class Preheader < Element
      HIDDEN_STYLE = 'display:none;max-height:0;overflow:hidden'.freeze
      
      def initialize(text = nil, **attrs)
        super(**attrs)
        @text = text
      end
            
      def to_s
        content = @block ? capture_body : @text
        content_div = tag.div(style: HIDDEN_STYLE) { content }
        filler = tag.div(class: "preheader", style: "#{HIDDEN_STYLE};width:0;height:0") { '&#847;&zwnj;&nbsp;' * 90 }

        safe_join([content_div, filler])
      end
    end

    class TitlebarLink < Element
      def initialize(link_html = nil, **attrs)
        super(**attrs)
        @link_html = link_html
      end
            
      def to_s
        content = @block ? capture_body : @link_html
        tag.div class: "titlebar_link tac pt10 pb10 pl5 pr5" do # TODO: adjust styling differently
          "<!--[if gte mso 12]><br><![endif]-->#{content}<!--[if gte mso 12]><br><![endif]-->".html_safe
        end
      end
    end
    
    class Divider < Element
      self.default_email_options = { class: "divider MsoNormal" }

      def to_s
        content = tag.p('<o:p>&nbsp;</o:p>'.html_safe, **email_options)
        DSL::Current.parent.is_a?(VStack) ? tag.tr { tag.th { content } } : content
      end
    end

    class Image < Element
      self.default_email_options = { alt: '', link_url: nil, width: 130, height: 50, valign: 'top', align: 'left', class: '', style: "background-color: transparent;outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; display: block; border: none" }
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

      def initialize(source = nil, **attrs)
        super(**attrs)
        @source = source
      end

      def to_s
        options = email_options
        link_url = options.delete(:link_url)

        content = tag.th do
          link_to_if_true(link_url.present?, link_url, target: '_blank') do
            image_tag(@source, options)
          end
        end

        DSL::Current.parent.is_a?(VStack) ? tag.tr { content } : content
      end

    end

    class TextContent < Element
      def initialize(text = nil, **attrs)
        super(**attrs)
        @text = text
      end
      
      def to_s
        content = @block ? capture_body : @text
        default = { valign: 'top', style:  'mso-line-height-rule:exactly;text-align:left;font-weight:400' }
        if DSL::Current.parent.is_a?(VStack)
          tag.tr do
            tag.td(content, **email_options)
          end
        else
          tag.td(content, **email_options)
        end
      end
    end

    # class ZStack < Element
    #   attr_reader :children
    
    #   def initialize(**attrs, &block)
    #     super
    #     unless email_options[:width]
    #       raise ArgumentError, "ZStack requires a :width option"
    #     end
    #     unless email_options[:height]
    #       raise ArgumentError, "ZStack requires a :height option"
    #     end
    #     @children = []
    #     # Set the current parent to self so that "item" calls found in the block
    #     # will use our item method.
    #     prev = DSL::Current.parent
    #     DSL::Current.parent = self
    #     instance_eval(&block) if block_given?
    #   ensure
    #     DSL::Current.parent = prev
    #   end

    #   def item(**options, &block)
    #     child = ZStackItem.new(**options, &block)
    #     @children << child
    #     nil
    #   end
    
    #   def to_s
    #     container_width  = email_options[:width]
    #     container_height = email_options[:height]
    
    #     # HTML markup for modern email clients.
    #     html_markup = tag.table(
    #       email_options.merge(style: "position: relative; width: #{container_width}px; height: #{container_height}px"),
    #       cellpadding: "0",
    #       cellspacing: "0",
    #       border: "0",
    #       width: container_width
    #     ) do
    #       tag.tbody do
    #         safe_join(@children.map(&:html_markup))
    #       end
    #     end
    
    #     # VML markup for Outlook—wrapped in MSO conditionals.
    #     mso_markup = <<~HTML
    #       <!--[if mso]>
    #       <v:group style="position:relative;width:#{container_width}px;height:#{container_height}px" coordsize="#{container_width},#{container_height}">
    #         #{safe_join(@children.map(&:vml_markup))}
    #       </v:group>
    #       <![endif]-->
    #     HTML
    
    #     # Wrap the HTML version in a negative conditional so Outlook ignores it.
    #     wrapped_html_markup = <<~HTML
    #       <!--[if !mso]><!-- -->
    #       #{html_markup}
    #       <!--<![endif]-->
    #     HTML
    
    #     safe_join([mso_markup.html_safe, wrapped_html_markup.html_safe])
    #   end
    # end

    # class ZStackItem < Element
    #   # For a ZStackItem you must provide explicit positioning/dimensions.
    #   # For example: left: 0, top: 0, width: 300, height: 200.
    #   def html_markup
    #     left   = email_options[:left] || 0
    #     top    = email_options[:top] || 0
    #     width  = email_options[:width] or raise ArgumentError, "ZStackItem requires a :width option"
    #     height = email_options[:height] or raise ArgumentError, "ZStackItem requires a :height option"
    
    #     style = "position: absolute; left: #{left}px; top: #{top}px; width: #{width}px; height: #{height}px;"
    #     html_opts = email_options.merge(style: style)
    #     tag.div(capture_body, html_opts)
    #   end
    
    #   def vml_markup
    #     left   = email_options[:left] || 0
    #     top    = email_options[:top] || 0
    #     width  = email_options[:width] or raise ArgumentError, "ZStackItem requires a :width option"
    #     height = email_options[:height] or raise ArgumentError, "ZStackItem requires a :height option"
    #     content = capture_body
    
    #     <<~HTML
    #       <v:rect style="position:absolute; left: #{left}px; top: #{top}px; width: #{width}px; height: #{height}px;" fill="false" stroke="false">
    #         <v:textbox inset="0,0,0,0">
    #           #{content}
    #         </v:textbox>
    #       </v:rect>
    #     HTML
    #   end
    # end

    class Item < Element
      def to_s
        case DSL::Current.parent
        when VStack
          tag.tr do
            tag.th(capture_body, **email_options)
          end
        else
          tag.th(capture_body, **email_options)
        end
      end
    end

    class LayoutTable < Element
      self.default_email_options = { width: 600, style: "background-color: #FFFFFF" }
      self.default_email_options = {  valign: 'top', cellpadding: '0', cellspacing: '0', border: '0', width: 600, style: 'margin: 0; padding: 0; text-align: left; width: 100%; min-width: 600px; line-height: 100%;', role: 'presentation', background: '#FFFFFF', class: 'background-table has-width-600', bgcolor: '#FFFFFF'}
            
      def to_s
        tag.table(email_options) do
          tag.tbody do
            tag.tr do
              tag.th(valign: "top") do
                tag.table(cellpadding: '0', cellspacing: '0', border: '0', width: email_options[:width], style: "width:#{email_options[:width]}px; margin:0 auto", role: 'presentation', class: "#{email_options[:class]} email-content", align: 'center') do
                  tag.tbody do
                    tag.tr do
                      tag.th(valign: "top") do
                        tag.div(capture_body)
                      end
                    end
                  end
                end
              end
            end
          end
        end

      end
    end

    class MailBuilder
      include TagExtensions
    end

    def fx
      DSL::Current.view ||= (respond_to?(:capture) ? self : nil) 
      @fx ||= MailBuilder.new 
    end

  end
end