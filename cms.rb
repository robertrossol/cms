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

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

root = File.expand_path("..", __FILE__)
files = Dir.glob(root + "/data/*").map do |path|
  File.basename(path)
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  # @files = files
  # @text_files = Dir.entries('.').select{|file| file.split('.').last == "txt"}.sort
  # @files = Dir.glob(root + "/data/*").map do |path|
  #   File.basename(path)
  # end
  erb :index
end

get "/:file_name" do
  file_path = File.join(data_path, params[:file_name])
  # pathname = root + "/data/" + params[:file_name]
  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:file_name]} does not exist"
    redirect "/"
  end
end

get "/:file_name/edit" do
  # pathname = root + "/data/" + params[:file_name]
  file_path = File.join(data_path, params[:file_name])
  @content = File.read(file_path)

  erb :edit
end

post "/:file_name" do
  file_path = File.join(data_path, params[:file_name])
  # pathname = root + "/data/" + params[:file_name]
  File.write(file_path, params[:content])
  session[:message] = "#{params[:file_name]} has been updated!"
  redirect "/"
end