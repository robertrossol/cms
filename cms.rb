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
      erb render_markdown(content)
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

get "/new" do
  @files = files
  erb :new
end

post "/create" do
  @files = files
  file_name = params[:file_name].to_s
  if file_name.empty? || @files.include?(file_name) || File.extname(file_name).empty?
    session[:message] = "File name must be unique, greater than 0 characters, and have a valid extension"
    status 422
    erb :new
  else
    file_path = File.join(data_path, file_name)
    File.write(file_path, "")
    session[:message] = "#{file_name} was created"
    redirect "/"
  end
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

post "/:file_name/delete" do
  file_path = File.join(data_path, params[:file_name])
  
  File.delete(file_path)

  session[:message] = "#{params[:file_name]} has been deleted!"
  redirect "/"
end
