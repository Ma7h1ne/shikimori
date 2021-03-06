class ViewObjectBase
  include Draper::ViewHelpers
  include Translation

  prepend ActiveCacher.instance
  extend DslAttribute

  dsl_attribute :per_page_limit

  def page
    (h.params[:page] || 1).to_i
  end

  def read_attribute_for_serialization attribute
    send attribute
  end
end
