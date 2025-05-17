class BooksController < ApplicationController
  def index
    response = HTTParty.get("http://localhost:3000/api/v1/books")
    @books = response.parsed_response
  end
end
