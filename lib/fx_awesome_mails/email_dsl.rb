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
      
      def tag_name = :div  # subclasses override when needed
      
      protected
      def capture_body
        prev = DSL::Current.parent
        DSL::Current.parent = self
        (@block ? @view.capture(self, &@block) : "")&.html_safe
      ensure
        DSL::Current.parent = prev
      end
    end
    

    class Spacer < Element
      def initialize(size = 16, **a)
        super(size: size, **a)
      end
      def tag_name = :td       # irrelevant; we override to_s
      
      def to_s
        in_hstack = DSL::Current.parent.is_a?(HStack)
        opts = {
          class: (in_hstack ? 'hstack_spacer' : 'vstack_spacer'),
          style: 'font-size:0;line-height:0;mso-line-height-rule:exactly'
        }
        opts[in_hstack ? :width : :height] = @attrs[:size]
        
        options = {valign: 'top', class: '',style: "text-align:left;font-size:1px;line-height:1px"}.merge_email_options(@attrs)
        
        if in_hstack
          @view.content_tag('th', '&nbsp;'.html_safe, height: @attrs[:size], valign: "#{options[:valign]}", style: "#{options[:style]}", class: "#{options[:class]} horizontal-spacer horizontal-gutter", bgcolor: options[:style].to_s.to_css_hash["background-color"].try(&:to_s))
        else
          @view.content_tag('th', '&nbsp;'.html_safe, width: @attrs[:size], valign: "#{options[:valign]}", style: "#{options[:style]}", class: "#{options[:class]} vertical-spacer vertical-gutter", bgcolor: options[:style].to_s.to_css_hash["background-color"].try(&:to_s))
        end
      end
    end

    
    class HStack < Element
      def tag_name = :div
      
      def initialize(**a)
        super(**a)
      end

      def to_s
        options = { valign: 'top', style: "text-align: left" }.merge_email_options(@attrs)

        if DSL::Current.parent.is_a?(VStack)
          "<tr><th valign='#{options[:valign]}' style='#{options[:style]}' class='#{options[:class]} horizontal-stack horizontal-grid'>
            <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
              <tbody>
                <tr>
                  #{capture_body}
                </tr>
              </tbody>
            </table>
          </th></tr>".html_safe

        else
          "<th valign='#{options[:valign]}' style='#{options[:style]}' class='#{options[:class]} horizontal-stack horizontal-grid'>
            <table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
              <tbody>
                <tr>
                  #{capture_body}
                </tr>
              </tbody>
            </table>
          </th>".html_safe
        end
      end
    end
    
    class VStack < Element # Apply same logging to HStack
      
      def initialize(**a)
        super(**a)
      end

      def to_s
        options = { valign: 'top', style: "text-align: left" }.merge_email_options(@attrs)

        if DSL::Current.parent.is_a?(VStack)
          @view.content_tag("tr") do
            @view.content_tag('th', valign: "#{options[:valign]}", style: "#{options[:style]}", class: "vertical-stack vertical-grid #{options[:class]}") do
              "<table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
                <tbody>
                  #{capture_body}
                </tbody>
              </table>".html_safe
            end
          end

        else
          @view.content_tag('th', valign: "#{options[:valign]}", style: "#{options[:style]}", class: "vertical-stack vertical-grid #{options[:class]}") do
            "<table cellpadding='0' cellspacing='0' border='0' width='100%' style='min-width:100%' role='presentation'>
              <tbody>
                #{capture_body}
              </tbody>
            </table>".html_safe
          end
        end
      end
    end

    class Preheader < Element
      HIDDEN_STYLE = 'display:none;max-height:0;overflow:hidden'.freeze
      
      def initialize(text = nil, **attrs, &block)
        @text, @block = text, block
        super(**attrs)
      end
      
      def tag_name = :div
      
      def to_s
        content = @block ? capture_body : @text
        filler   = '&#847;&zwnj;&nbsp;' * 90
        hidden_1 = @view.content_tag(:div, content, style: HIDDEN_STYLE)
        hidden_2 = @view.content_tag(:div, filler, class: 'preheader', style: "#{HIDDEN_STYLE};width:0;height:0")
        (hidden_1 + hidden_2).html_safe
      end
    end

    class TitlebarLink < Element
      def initialize(link_html = nil, **attrs, &block)
        super(**attrs)
        @link_html, @block = link_html, block
      end
      
      def tag_name = :div
      
      def to_s
        content = @block ? capture_body : @link_html
        @view.content_tag(:div,
          "<!--[if gte mso 12]><br><![endif]-->#{content}<!--[if gte mso 12]><br><![endif]-->".html_safe,
          class: 'tac pt10 pb10 pl5 pr5').html_safe
      end
    end
    
    class Divider < Element
      def tag_name = :p
      def to_s
        @view.content_tag(:p, '<o:p>&nbsp;</o:p>'.html_safe, class: 'MsoNormal').html_safe
      end
    end

    class Image < Element

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
        options = { alt: '', link_url: nil, width: 130, height: 50, valign: 'top', align: 'left', class: '', style: "background-color: transparent;outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; display: block; border: none" }.merge_email_options(options)
        html = ""
        html << "<tr>" if DSL::Current.parent.is_a?(VStack)
        html << "<th valign='#{options[:valign]}' style='text-align:#{options[:align]}' class='#{options[:class]} image-container' bgcolor='#{options[:style].to_s.to_css_hash["background-color"]}' align='#{options[:align]}'>"
        html << link_to_if_true(options[:link_url].present?, options[:link_url], target: '_blank') do
          image_tag(@source, style: options[:style], width: "#{options[:width]}", height: "#{options[:height]}", alt: "#{options[:alt]}")
        end
        html << "</th>"
        html << "</tr>" if DSL::Current.parent.is_a?(VStack)
        html.html_safe
      end

    end

    class TextContent < Element
      def initialize(text = nil, **attrs, &block)
        super(**attrs)
        @text, @block = text, block
      end
      
      def tag_name = :td
      def to_s
        content = @block ? capture_body : @text
        default = { valign: 'top', style:  'mso-line-height-rule:exactly;text-align:left;font-weight:400' }
        if DSL::Current.parent.is_a?(VStack)
          @view.content_tag(:tr) do
            @view.content_tag(:td, content, **default.merge_email_options(@attrs)).html_safe
          end
        else
          @view.content_tag(:td, content, **default.merge_email_options(@attrs)).html_safe
        end
      end
    end

    class EmailContent < Element
      def tag_name = :table
      def to_s
        w  = (@attrs[:width] || 600).to_i
        bg = (@attrs[:style] || '').to_css_hash['background-color'] || '#FFFFFF'
        inner = @view.content_tag(:table,
                  @view.content_tag(:tr,
                    @view.content_tag(:th, capture_body, valign: 'top')),
                  cellpadding: 0, cellspacing: 0, border: 0,
                  width: w, style: "width:#{w}px;margin:0 auto", role: 'presentation')
        @view.content_tag(:table,
          @view.content_tag(:tr, @view.content_tag(:th, inner)),
          cellpadding: 0, cellspacing: 0, border: 0,
          width: w, bgcolor: bg,
          style: "margin:0;padding:0;text-align:left;width:100%;min-width:#{w}px;line-height:100%").html_safe
      end
    end

  end
end