module Spree
  module Stock
    class Packer
      attr_reader :stock_location, :inventory_units, :splitters

      def initialize(stock_location, inventory_units, splitters = [Splitter::Base])
        @stock_location = stock_location
        @inventory_units = inventory_units
        @splitters = splitters
      end

      def packages
        if splitters.empty?
          [default_package]
        else
          build_splitter.split [default_package]
        end
      end

      def default_package
        package = Package.new(stock_location)

        inventory_units.index_by(&:line_item_id).each do |line_item_id, inventory_unit|
          line_item = Spree::LineItem.find(line_item_id)
          variant = line_item.variant
          unit = inventory_unit.dup # Can be used by others, do not use directly
          if variant.should_track_inventory?
            next unless stock_location.stocks? variant

            on_hand, backordered = stock_location.fill_status(variant, unit.quantity)
            package.add(InventoryUnit.split(unit, backordered), :backordered) if backordered.positive?
            package.add(InventoryUnit.split(unit, on_hand), :on_hand) if on_hand.positive?
          else
            package.add unit
          end
        end

        package
      end

      private

      def build_splitter
        splitter = nil
        splitters.reverse_each do |klass|
          splitter = klass.new(self, splitter)
        end
        splitter
      end
    end
  end
end
