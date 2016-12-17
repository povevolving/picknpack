module ApplicationHelper
  def svg_icon_tag(icon)
    File.read(File.join(Rails.root, "app/assets/images/#{icon}.svg")).html_safe
  end
end
