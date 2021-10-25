module FXAwesomeMails
  module CoreExtensions
    module Hash
      module Merging
        def deep_merge_v2(second)
          merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
          merge(second.to_h, &merger)
        end
      
        def merge_email_options(second)
          merger = proc { |k, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : [:style, :class].include?(k) ? v1.merge_css_options(v2, k) : v2}
          merge(second.to_h, &merger)
        end
      end
    end

    module String
      module Merging
        def merge_css_options(second, key)
          return self&.strip if second.blank?
          return second&.strip if self.blank?
          
          case key
          when :style
            return self.strip.to_css_hash.deep_merge_v2(second.strip.to_css_hash).map {|k,v| [k,v].join(':') }.join(';')
          when :class
            self.strip.split(' ').union(second.strip.split(' ')).join(' ')
          else
            return ""
          end
        end
        
        def to_css_hash
          Hash[self.split(';').map { _1.split(':').map(&:strip) }]
        end
      end
    end
  end
end