set :base_url, "https://www.vaultproject.io/"

# Middleware for rendering preact components
use ReshapeMiddleware, component_file: "assets/reshape.js"

activate :hashicorp do |h|
  h.name        = "vault"
  h.version     = "0.10.4"
  h.github_slug = "hashicorp/vault"
  h.website_root = "website"
  h.releases_enabled = true
  h.minify_css = false
  h.minify_javascript = false
  h.hash_assets = false
end

# compile js with webpack, css with postcss
activate :external_pipeline,
  name: 'assets',
  command: "cd assets && ./node_modules/.bin/spike #{build? ? :compile : :watch}",
  source: 'assets/public'

# pull site data from datocms
activate :dato,
  token: '78d2968c99a076419fbb'

dato.tap do |dato|
  sitemap.resources.each do |page|
    if page.path.match(/\.html$/)
      if page.metadata[:options][:layout]
        proxy "#{page.path}", "/content", {
          layout: page.metadata[:options][:layout],
          locals: page.metadata[:page].merge({ content: render(page) })
        }
      end
    end

  end
end

helpers do
  # Formats and filters a category of docs for the sidebar component
  def sidebar_data(category)
    sitemap.resources.select { |resource|
      Regexp.new("^#{category}").match(resource.path)
    }.map { |resource|
      {
        path: resource.path,
        data: resource.data.to_hash.tap { |a| a.delete 'description'; a }
      }
    }
  end

  # Returns the FQDN of the image URL.
  # @param [String] path
  # @return [String]
  def image_url(path)
    File.join(config[:base_url], "/img/#{path}")
  end

  # Get the title for the page.
  #
  # @param [Middleman::Page] page
  #
  # @return [String]
  def title_for(page)
    if page && page.data.page_title
      return "#{page.data.page_title} - Vault by HashiCorp"
    end

     "Vault by HashiCorp"
   end

  # Get the description for the page
  #
  # @param [Middleman::Page] page
  #
  # @return [String]
  def description_for(page)
    description = (page.data.description || "")
      .gsub('"', '')
      .gsub(/\n+/, ' ')
      .squeeze(' ')

    return escape_html(description)
  end

  # This helps by setting the "active" class for sidebar nav elements
  # if the YAML frontmatter matches the expected value.
  def sidebar_current(expected)
    current = current_page.data.sidebar_current || ""
    if current.start_with?(expected)
      return " class=\"active\""
    else
      return ""
    end
  end

  # Returns the id for this page.
  # @return [String]
  def body_id_for(page)
    if !(name = page.data.sidebar_current).blank?
      return "page-#{name.strip}"
    end
    if page.url == "/" || page.url == "/index.html"
      return "page-home"
    end
    if !(title = page.data.page_title).blank?
      return title
        .downcase
        .gsub('"', '')
        .gsub(/[^\w]+/, '-')
        .gsub(/_+/, '-')
        .squeeze('-')
        .squeeze(' ')
    end
    return ""
  end

  # Returns the list of classes for this page.
  # @return [String]
  def body_classes_for(page)
    classes = []

    if !(layout = page.data.layout).blank?
      classes << "layout-#{page.data.layout}"
    end

    if !(title = page.data.page_title).blank?
      title = title
        .downcase
        .gsub('"', '')
        .gsub(/[^\w]+/, '-')
        .gsub(/_+/, '-')
        .squeeze('-')
        .squeeze(' ')
      classes << "page-#{title}"
    end

    return classes.join(" ")
  end
end

# A modified version of middleman's render that skips the layout, required in
# order to pass content into views as a local

def render(page, opts = {}, locs = {})
  return ::Middleman::FileRenderer.new(@app, page.file_descriptor[:full_path].to_s).template_data_for_file unless page.template?

  md   = page.metadata
  opts = md[:options].deep_merge(opts)
  locs = md[:locals].deep_merge(locs)
  locs[:current_path] ||= page.destination_path

  # Remove layout, we're only rendering the content
  opts.delete(:layout)

  renderer = ::Middleman::TemplateRenderer.new(@app, page.file_descriptor[:full_path].to_s)
  renderer.render(locs, opts)
end
