# jekyll-plantuml-url-interactive

[![Gem Version](https://badge.fury.io/rb/jekyll-plantuml-url.svg)](http://badge.fury.io/rb/jekyll-plantuml-url)


A plugin for Jekyll that provides integration of PlantUML diagrams inside Jekyll for deployment in your website.

This plugin makes use of  an external resource, defined by the configurable `plantulm:url`, to build the PlantUML diagram.

Once the diagram has been created, it is stored in the uml/ directory. So, using this plugin provides a simple way to integrate PlantUML diagrams without needing the Gaphviz libraries, Java, or PlantUML jar file.

## Install Jekyll plugin

Install it first:

```
gem install jekyll-plantuml-url-interactive
```

With Jekyll 2, simply add the gem to your `_config.yml` gems list:

```yaml
gems:
  - 'jekyll-plantuml-url-interactive'
  - ...
```

Or for previous versions,
create a plugin file within your Jekyll project's `_plugins` directory:

```ruby
# _plugins/plantuml-plugin.rb

require "jekyll-plantuml-url-interactive"
```

Highly recommend to use Bundler. If you're using it, add this line
to your `Gemfile`:

```
gem "jekyll-plantuml-url-interactive"
```

## choose a PlantUML-Server

Checkout [PlantUML-Server](https://github.com/plantuml/plantuml-server) to install your own plantUML server or use http://www.plantuml.com/plantuml.

and setup the `_config.yml`

```yaml
plantuml:
  url:          'http://www.plantuml.com/plantuml' 
  type:         'svg'
  ssl_noverify: '0'
  http_debug:   '0'
```

If above settings are not defined, the above values are the default settings.

## Test

Now, it's time to create a diagram, in your Jekyll blog page:

```
{% plantuml %}
[First] - [Second]
{% endplantuml %}
```

