require "action_view"
require "active_support"

module FXAwesomeMails

  module DSL
    class Current < ActiveSupport::CurrentAttributes
      attribute :view, :parent
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
      
      def initialize(text = nil, **attrs, &block)
        super(**attrs)
        @text, @block = text, block
      end
            
      def to_s
        content = @block ? capture_body : @text
        content_div = tag.div(style: HIDDEN_STYLE) { content }
        filler = tag.div(class: "preheader", style: "#{HIDDEN_STYLE};width:0;height:0") { '&#847;&zwnj;&nbsp;' * 90 }

        safe_join([content_div, filler])
        # (content_div + filler).html_safe
      end
    end

    class TitlebarLink < Element
      def initialize(link_html = nil, **attrs, &block)
        super(**attrs)
        @link_html, @block = link_html, block
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
        DSL::Current.parent.is_a?(VStack) ? tag.tr { content } : content
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
      def initialize(text = nil, **attrs, &block)
        super(**attrs)
        @text, @block = text, block
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

    class ZStack < Element
      def to_s
      container_style = "position: relative; width: 100%; height: 100%"
    
        # Wrap the content (yielded via capture_body) in a table with one cell that is
        # relatively positioned so that its children (each rendered as an absolute element)
        tag.table(style: container_style, cellpadding: "0", cellspacing: "0", border: "0", width: "100%") do
          tag.tbody do
            tag.tr do
              tag.td(style: "position: relative") do
                capture_body
              end
            end
          end
        end
      end
    end
      
    class ZStackItem < Element
      def to_s
        # Each ZStackItem will be layered in the same container using absolute positioning.
        # You might further customize properties (e.g. setting a z-index) via attrs if needed.
        absolute_style = "position: absolute; top: 0; left: 0; width: 100%"
    
        tag.div(capture_body, style: absolute_style)
      end
    end
    

    class EmailContent < Element
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

  end
end