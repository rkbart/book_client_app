class UsersController < ApplicationController
  def index
    response = HTTParty.get("http://localhost:3000/api/v1/users")
    @users = response.parsed_response
  end

  def show
    response = HTTParty.get("http://localhost:3000/api/v1/users/#{params[:id]}")
    @user = response.parsed_response
    @books =HTTParty.get("http://localhost:3000/api/v1/users/#{params[:id]}/books").parsed_response
  end

  def create
    response = HTTParty.post(
      "http://localhost:3000/api/v1/users",
      body: {
        user: {
          name: params.dig(:user, :name),
          email: params.dig(:user, :email)
        }
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    )

    if response.code == 201
      redirect_to users_path, notice: "User created successfully!"
    else
      flash.now[:alert] = "Error: #{response.parsed_response['errors'] || 'Unknown error'}"
      @users = HTTParty.get("http://localhost:3000/api/v1/users").parsed_response
      render :index
    end
  end
end
