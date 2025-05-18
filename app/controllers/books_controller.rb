class BooksController < ApplicationController
  rescue_from HTTParty::Error, with: :handle_api_error
  rescue_from StandardError, with: :handle_generic_error
  def index
    response = HTTParty.get("http://localhost:3000/api/v1/books")
    @books = response.parsed_response
  end

  def show
    user_id = params[:user_id]
    book_id = params[:id]
    
    begin
      # Fetch book data with timeout protection
      book_response = HTTParty.get(
        "http://localhost:3000/api/v1/users/#{user_id}/books/#{book_id}",
        timeout: 5 # 5 second timeout
      )
      
      unless book_response.success?
        raise "API request failed: #{book_response.code} - #{book_response.message}"
      end

      @book = book_response.parsed_response || {}
      @book["category"] ||= { "name" => "Uncategorized" } # Default category

      # Fetch user data
      user_response = HTTParty.get(
        "http://localhost:3000/api/v1/users/#{user_id}",
        timeout: 5
      )

      @user = user_response.success? ? (user_response.parsed_response || {}) : {}

    rescue HTTParty::Error => e
      redirect_to users_path, alert: "Couldn't connect to API: #{e.message}"
    rescue JSON::ParserError
      redirect_to users_path, alert: "Invalid API response format"
    rescue => e
      logger.error "Book show error: #{e.message}\n#{e.backtrace.join("\n")}"
      redirect_to users_path, alert: "Something went wrong"
    end
  end

  def edit
    user_id = params[:user_id]
    book_id = params[:id]

    # Fetch book data
    book_response = HTTParty.get("http://localhost:3000/api/v1/users/#{user_id}/books/#{book_id}")
    if book_response.success?
      @book = book_response.parsed_response || {} # No longer looking for ["data"]
    else
      redirect_to user_books_path(user_id), alert: "Book not found"
      return
    end

    # Fetch categories
    categories_response = HTTParty.get("http://localhost:3000/api/v1/categories")
    @categories = categories_response.success? ? (categories_response.parsed_response || categories_response.parsed_response || []) : []
  end

  def update
    user_id = params[:user_id]
    book_id = params[:id]

    response = HTTParty.patch(
      "http://localhost:3000/api/v1/users/#{user_id}/books/#{book_id}",
      body: {
        book: {
          title: params[:book][:title],
          author: params[:book][:author],
          category_id: params[:book][:category_id]
        }
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    )

    if response.success?
      redirect_to user_book_path(user_id, book_id), notice: "Book updated successfully!"
    else
      @user = HTTParty.get("http://localhost:3000/api/v1/users/#{user_id}").parsed_response || {}
      @book = HTTParty.get("http://localhost:3000/api/v1/users/#{user_id}/books/#{book_id}").parsed_response || {}
      @categories = HTTParty.get("http://localhost:3000/api/v1/categories").parsed_response || []
      flash.now[:alert] = "Error updating book: #{response.parsed_response['errors'] || 'Unknown error'}"
      render :edit
    end
  end
  def new
    @user = HTTParty.get("http://localhost:3000/api/v1/users/#{params[:user_id]}").parsed_response || {}
    @categories = HTTParty.get("http://localhost:3000/api/v1/categories").parsed_response || []
    @book = {} # Empty hash for the form
  end

  def create
    response = HTTParty.post(
      "http://localhost:3000/api/v1/users/#{params[:user_id]}/books",
      body: {
        book: {
          title: params[:book][:title],
          author: params[:book][:author],
          user_id: params[:user_id],
          category_id: params[:book][:category_id]
        }
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    )

    if response.success?
      redirect_to user_path(params[:user_id]), notice: "Book created successfully!"
    else
      @user = HTTParty.get("http://localhost:3000/api/v1/users/#{params[:user_id]}").parsed_response || {}
      @categories = HTTParty.get("http://localhost:3000/api/v1/categories").parsed_response || []
      flash.now[:alert] = "Error creating book: #{response.parsed_response['errors'] || 'Unknown error'}"
      render :new
    end
  end

  def destroy
    user_id = params[:user_id]
    book_id = params[:id]
    response =  HTTParty.delete("http://localhost:3000/api/v1/users/#{user_id}/books/#{book_id}")

    if response.success?
      redirect_to user_path(user_id), notice: "Book deleted successfully!"
    else
      redirect_to user_path(user_id), alert: "Failed to delete book: #{response.parsed_response['error'] || 'Unknown error'}"
    end
  end

  private

  def handle_api_error(exception)
    logger.error "API Error: #{exception.message}"
    redirect_to users_path, alert: "Service temporarily unavailable. Please try again later."
  end

  def handle_generic_error(exception)
    logger.error "Error: #{exception.message}\n#{exception.backtrace.join("\n")}"
    redirect_to users_path, alert: "An unexpected error occurred."
  end
end
