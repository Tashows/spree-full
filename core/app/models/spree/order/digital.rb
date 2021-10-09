module Spree
  class Order < Spree::Base
    module Digital
      def digital?
        return if line_items.empty?

        line_items.all?(&:digital?)
      end

      def some_digital?
        line_items.any?(&:digital?)
      end

      def digital_line_items
        line_items.select(&:digital?)
      end

      def digital_links
        digital_line_items.map(&:digital_links).flatten
      end

      def reset_digital_links!
        digital_links.each(&:reset!)
      end

      def create_digital_links
        digital_line_items.each do |line_item|
          line_item.variant.digitals.each do |digital|
            line_item.digital_links.create!(digital: digital)
          end
        end
      end
    end
  end
end
