class Curlser
  
  class Response
    
    attr_reader :status, :connections, :redirects, :url_effective, :content_type
    attr_accessor :method, :path, :for_request_number, :body
    
    
    def initialize(opts)
      @status = opts[:status]
      @connections = opts[:connections]
      @redirects = opts[:redirects]
      @url_effective = opts[:url_effective]
      @content_type = opts[:content_type]
    end
    
    def self.parse_from(output)
      matches = output.match(/^(\d*) (\d*) (\d*) (\S*) (.*)$/)
      
      new({:status => matches[1],
           :connections => matches[2],
           :redirects => matches[3],
           :url_effective => matches[4],
           :content_type => matches[5]})
    end
  end
  
  require 'fileutils'

  attr_reader :responses
  
  def initialize(base_url, opts={})
    
    @request_counter = 0
    @csrf_token = nil
    @responses = []
    
    @base_url = base_url    
    @working_dir = opts[:working_dir] ? opts[:working_dir] : "curlser"
    @follow_redirects = opts[:follow_redirects] ? true : false
    @debug = opts[:debug] ? true : false
    
    FileUtils.mkdir_p @working_dir
  end


  def get(path)
    response = request("GET", path)
    response_with_body = save_response_with_body(response)
    
    find_and_save_csrf_from(response_with_body.body)
  end
  
  def post(path, params, body = "")
    response = request("POST", path, params, body)
    save_response_with_body(response)
  end
  
  def put(path, params, body = "")
    response = request("PUT", path, params, body)
    save_response_with_body(response)
  end

  def delete(path, params, body = "")
    response = request("DELETE", path, params, body)
    save_response_with_body(response)
  end


  private
  
  def save_response_with_body(response)
    body = File.read("#{@working_dir}/response_#{@request_counter}")
    response.body = body
    
    @responses << response
    
    return response
  end
  
  def request(method, path, params={}, body = "")
    @request_counter += 1
    
    url = @base_url + path

    data_params = build_data_params_and_from(params, body)
    csrf_param = build_csrf_param unless method == "GET"
    
    verbose_mode = "-v" if @debug
    
    # -s silent, -S show errors with silent
    # -L follow redirects
    # --post302, do not change POST to GET when redirecting
    # -e ';auto' set referrer automatically
    # -c store cookies in this file
    # -b submit cookies from this file
    
    redirect_behaviour = "-L --post302" if @follow_redirects

    command = "curl #{verbose_mode} -s -S #{redirect_behaviour} -e ';auto' -w '%{http_code} %{num_connects} %{num_redirects} %{url_effective} %{content_type}' -c #{@working_dir}/cookie-jar -b #{@working_dir}/cookie-jar -X #{method} #{data_params} #{csrf_param} -o #{@working_dir}/response_#{@request_counter} #{url}"
    puts command if @debug
    output = `#{command}`

    response = Response.parse_from(output)
    response.method = method
    response.path = path
    response.for_request_number = @request_counter
    
    return response
  end

  
  def build_data_params_and_from(params, body)
    data_params = ""
    params.each_pair do |key, value|
      data_params += " -d '#{key}=#{value}'"
    end

    data_params += " -d '#{body}'" unless body == ""
    
    return data_params  
  end

  def build_csrf_param()
    " -d 'authenticity_token=#{@csrf_token}'" if @csrf_token
  end
    
  def find_and_save_csrf_from(contents)
    matches = contents.match(/csrf-token" content="([^\"]*)"/)
    
    @csrf_token = matches[1] if matches && matches[1]    
  end
  
end






# 
# class Capybara::Driver::Curlser < Capybara::Driver::Base
# 
#   attr_reader :app, :rack_server, :options
# 
#   def browser
#     unless @browser
#       @browser = Curlser.new("http://localhost:#{Capybara.server_port}", :debug => true)
# 
# #      at_exit do
# #        @browser.quit
# #      end
#     end
#     @browser
#   end
# 
#   def initialize(app, options={})
#     @app = app
#     @options = options
#     @rack_server = Capybara::Server.new(@app)
#     @rack_server.boot if Capybara.run_server
#   end
# 
#   def visit(path)
#     browser.get(path)
#   end
# 
#   def source
#     browser.responses.last.body
#   end
# 
#   def body
#     browser.responses.last.body
#   end
# 
#   def find(selector)
#     raise "plz implement, somebody asked find with #{selector.inspect}"
#   end
#   
# #  def wait?; true; end
# 
# end
