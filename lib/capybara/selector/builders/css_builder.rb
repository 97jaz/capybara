# frozen_string_literal: true

require 'xpath'

module Capybara
  class Selector
    # @api private
    class CSSBuilder
      class << self
        def attribute_conditions(attributes)
          attributes.map do |attribute, value|
            case value
            when XPath::Expression
              raise ArgumentError, "XPath expressions are not supported for the :#{attribute} filter with CSS based selectors"
            when Regexp
              Selector::RegexpDisassembler.new(value).substrings.map do |str|
                "[#{attribute}*='#{str}'#{' i' if value.casefold?}]"
              end.join
            when true
              "[#{attribute}]"
            when false
              ':not([attribute])'
            else
              if attribute == :id
                "##{::Capybara::Selector::CSS.escape(value)}"
              else
                "[#{attribute}='#{value}']"
              end
            end
          end.join
        end

        def class_conditions(classes)
          case classes
          when XPath::Expression
            raise ArgumentError, 'XPath expressions are not supported for the :class filter with CSS based selectors'
          when Regexp
            Selector::RegexpDisassembler.new(classes).alternated_substrings.map do |strs|
              strs.map do |str|
                "[class*='#{str}'#{' i' if classes.casefold?}]"
              end.join
            end
          else
            cls = Array(classes).group_by { |cl| cl.start_with?('!') && !cl.start_with?('!!!') }
            [(cls[false].to_a.map { |cl| ".#{Capybara::Selector::CSS.escape(cl.sub(/^!!/, ''))}" } +
            cls[true].to_a.map { |cl| ":not(.#{Capybara::Selector::CSS.escape(cl.slice(1..-1))})" }).join]
          end
        end

        def id_conditions(id)
          case id
          when Regexp
            Selector::RegexpDisassembler.new(id).alternated_substrings.map do |id_strs|
              id_strs.map do |str|
                "[id*='#{str}'#{' i' if id.casefold?}]"
              end.join
            end
          else
            [attribute_conditions(id: id)]
          end
        end
      end
    end
  end
end
