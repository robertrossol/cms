require "sinatra"
require "sinatra/reloader" if development?
# require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"


configure do
  enable :sessions
  set :session_secret, 'super   secret'
  # set :erb, :escape_html => true
end

helpers do
  def render_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end

  def load_file_content(path)
    content = File.read(path)
    case File.extname(path)
    when ".txt"
      headers["Content-Type"] = "text/plain"
      content
    when ".md"
      render_markdown(content)
    end
  end
end


root = File.expand_path("..", __FILE__)
files = Dir.glob(root + "/data/*").map do |path|
  File.basename(path)
end

get "/" do
  @files = files
  # @text_files = Dir.entries('.').select{|file| file.split('.').last == "txt"}.sort
  # @files = Dir.glob(root + "/data/*").map do |path|
  #   File.basename(path)
  # end
  erb :index
end

get "/:file_name" do
  # if files.include?(params[:file_name])
  pathname = root + "/data/" + params[:file_name]
  if File.file?(pathname)
    load_file_content(pathname)
  else
    session[:error] = "#{params[:file_name]} does not exist"
    redirect "/"
  end
end