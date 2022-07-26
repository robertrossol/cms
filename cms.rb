require "sinatra"
require "sinatra/reloader" if development?
# require "sinatra/content_for"
require "tilt/erubis"

root = File.expand_path("..", __FILE__)

get "/" do
  # "Getting Started"
  # @text_files = Dir.entries('.').select{|file| file.split('.').last == "txt"}.sort
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :index
end

get "/:file_name" do
  headers["Content-Type"] = "text/plain"
  File.read("./data/#{params[:file_name]}")

  # File.read("./data/#{params[:file_name]}")
end