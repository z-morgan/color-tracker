class Inventory
  attr_reader :lines

  def initialize(lines)
    @lines = lines
  end

  # sorts the color objects in each line
  def sort_colors!(sort_params)
    sort_algo = case sort_params
                when ["depth", "ascending"]
                  Proc.new { |arr| sort_by_depth!(arr) }
                when ["depth", "descending"]
                  Proc.new { |arr| sort_by_depth!(arr).reverse! }
                when ["tone", "ascending"]
                  Proc.new { |arr| arr.sort_by!(&:tone) }
                when ["tone", "descending"]
                  Proc.new { |arr| arr.sort_by!(&:tone).reverse! }
                end

    lines.each_value(&sort_algo)
  end

  private

  def sort_by_depth!(arr)
    arr.sort_by! { |color| color.depth.to_i }
  end
end