module SiteHelper
  # ссылка на источник
  def source_link source
    if source =~ /(.*?)(https?:\/\/.*)/
      prefix = ($1 || '').strip
      url = $2

      domain = url.sub(/^https?:\/\/(?:www\.)?([^\/]+)\/?.*/, '\1')
      prefix.blank? ? "<a href=\"#{url}\">#{domain}</a>" : "#{prefix} <a href=\"#{url}\">#{domain}</a>"
    else
      source
    end
  end
end
