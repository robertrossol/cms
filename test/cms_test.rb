ENV["RACK_ENV"] = "test"

require "fileutils"
require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_response.body, "about.md")
    assert_includes(last_response.body, "changes.txt")
  end

  def test_view_text_doc
    create_document("history.txt", "2013 - Ruby 2.1 released.")

    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "2013 - Ruby 2.1 released."
  end

  def test_document_not_found
    get "/notafile.txt"

    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "notafile.txt does not exist"

    get "/"
    refute_includes last_response.body,  "notafile.txt does not exist"
  end

  def test_viewing_markdown_document
    create_document("about.md", "#Ruby is...")

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_edit_file
    create_document("changes.txt", "text for changes.txt")

    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end
  
  def test_updating_file
    post "/changes.txt", content: "updated text"

    assert_equal 302, last_response.status

    get last_response["location"]

    assert_includes last_response.body, "changes.txt has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "updated text"
  end

  def test_new
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "file_name"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_create
    post "/create", file_name: "thing.txt"

    assert_equal 302, last_response.status
    get last_response["location"]
    assert_includes last_response.body, "thing.txt was created"

    get "/"
    assert_includes last_response.body, "thing.txt"
  end

  def test_create_invalid
    post "/create", file_name: ""

    assert_equal 422, last_response.status
    assert_includes last_response.body, "File name must be unique, greater than 0 characters, and have a valid extension"

    post "/create", file_name: "changes.txt"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "File name must be unique, greater than 0 characters, and have a valid extension"
  end

  def test_delete
    create_document "test.txt"

    post "/test.txt/delete"
    
    assert_equal 302, last_response.status
  
    get last_response["location"]
    assert_includes last_response.body, "test.txt has been deleted!"

    get "/"
    refute_includes last_response.body, "test.txt"
  end
end