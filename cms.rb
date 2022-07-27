require "sinatra"
require "sinatra/reloader" if development?
# require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'super   secret'
  # set :erb, :escape_html => true
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
  if File.file?(root + "/data/" + params[:file_name])
    headers["Content-Type"] = "text/plain"
    File.read("./data/#{params[:file_name]}")
  else
    session[:error] = "#{params[:file_name]} does not exist"
    redirect "/"
  end
end