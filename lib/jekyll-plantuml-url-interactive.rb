# (The MIT License)
#
# Copyright (c) 2014-2017 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'digest'
require 'fileutils'
require 'net/http'
require 'uri'
require 'openssl'
require 'open-uri'

module Jekyll
  class PlantumlBlock < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      @html = (markup or '').strip
    end

    def render(context)
      site = context.registers[:site]
      name = Digest::MD5.hexdigest(super)
      if site.config['plantuml']
        uml_config=site.config['plantuml']
      else
        puts "** No configuration for plantuml in present in _config.yml, using default"
        #Jekyll.logger.debug "No configuration for plantuml in present in _config.yml, using default";
        uml_config={
          'type'         => 'svg',
          'url'          => 'http://www.plantuml.com/plantuml',
          'ssl_noverify' => '0',
          'http_debug'   => '0'
        }
      end
      if uml_config['type'] == ""
        uml_type="svg"
      else
        uml_type=uml_config['type']
      end
      if !File.exists?(File.join(site.dest, "uml/#{name}.#{uml_type}"))
        uml_out_file = File.join(site.source, "uml/#{name}.#{uml_type}")
        if File.exists?(uml_out_file)
          puts "File #{uml_out_file} already exists (#{File.size(uml_out_file)} bytes)"
        else
          if uml_config['url'] == ""
            uml_url="http://www.plantuml.com/plantuml"
            puts "using default url: #{uml_url}"
          else
            uml_url=uml_config['url']
            puts "using config url: #{uml_url}"
          end
          uri = URI.parse(uml_url)
          http = Net::HTTP.new(uri.host, uri.port)
          if uri.scheme == "https"
            http.use_ssl = true
            if uml_config['ssl_noverify'] == "1"
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
          end
          if uml_config['http_debug'] == "1"
            puts "*** http debug on ***"
            http.set_debug_output $stderr
          end

          request = Net::HTTP::Post.new("#{uri.path}/form")
          request.add_field('Content-Type', 'application/x-www-form-urlencoded')
          request.body = "text=" + URI::encode("@startuml\n"+super+"\n@enduml\n".force_encoding('ASCII-8BIT'))
          response = http.request(request)

          if response.code == "302" or response.code == "301"
            # expected redirect of 302 with a new url with code-hash
            newlocation=response["Location"]
            newlocation["/uml/"]= "/#{uml_type}/"
            begin # loop for 301 and 302 of the code request
              newuri = URI.parse(newlocation)
              if newuri.host != uri.host or newuri.port != uri.port or newuri.scheme != uri.scheme
                http = Net::HTTP.new(newuri.host, newuri.port)
                if newuri.scheme == "https"
                  http.use_ssl = true
                  if uml_config['ssl_noverify'] == "1"
                    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                  end
                end
                if uml_config['http_debug'] == "1"
                  puts "*** http debug on ***"
                  http.set_debug_output $stderr
                end
              end
              request_img = Net::HTTP::Get.new(newuri.path)
              response_img = http.request(request_img)
              if response_img.code == "200"
                #puts response_img.body
                FileUtils.mkdir_p(File.dirname(uml_out_file))
                File.open(uml_out_file, 'w') { |f|
                  f.write(response_img.body)
                }
                site.static_files << Jekyll::StaticFile.new( site, site.source, 'uml', "#{name}.#{uml_type}")
                puts "File #{uml_out_file} created (#{File.size(uml_out_file)} bytes)"
              elsif response_img.code == "302" or response_img.code == "301"
                # not expected www.plantuml.com redirect to plantuml.com, what a waste of time
                # it is what it is
                newlocation=response_img["Location"]
              else
                puts "error #{response_img.code} getting #{uri.host}#{request_img}"
              end
            end while  response_img.code == "302" or response_img.code == "301"
          else
            puts "Error #{response.code} getting #{uri.host}/plantuml/form "
          end
        end
      end
      "<p><object data='/uml/#{name}.#{uml_type}' #{@html}
        alt='PlantUML #{uml_type} diagram' class='plantuml interactive' type='image/svg+xml' style='position: relative; display: inline-block;'></object></p>"
    end
  end
end

Liquid::Template.register_tag('plantuml', Jekyll::PlantumlBlock)
