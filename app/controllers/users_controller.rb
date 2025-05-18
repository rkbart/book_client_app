class UsersController < ApplicationController
  rescue_from ApiError, with: :handle_api_error
  def index
    @users = Api::UserService.all
  rescue ApiError => e
    @users = []
    flash.now[:alert] = e.message
  end

  def show
    @user = Api::UserService.find(params[:id])
    @books = Api::UserService.user_books(params[:id])
  rescue ApiError => e
    redirect_to users_path, alert: e.message
  end

  def new
    @user = {} # Empty hash for form initialization
  end

  def create
    @user = Api::UserService.create(user_params)
    redirect_to users_path, notice: "User created successfully!"
  rescue ApiError => e
    flash.now[:alert] = e.message
    @users = Api::UserService.all rescue []
    render :index
  end

  def edit
    @user = Api::UserService.find(params[:id])
  rescue ApiError => e
    redirect_to users_path, alert: e.message
  end

  def update
    @user = Api::UserService.update(params[:id], user_params)
    redirect_to user_path(params[:id]), notice: "User updated successfully!"
  rescue ApiError => e
    flash.now[:alert] = e.message
    @user = Api::UserService.find(params[:id]) rescue {}
    render :edit
  end

  def destroy
    Api::UserService.destroy(params[:id])
    redirect_to users_path, notice: "User deleted successfully!"
  rescue ApiError => e
    redirect_to users_path, alert: e.message
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end

  def handle_api_error(exception)
    Rails.logger.error "API Error: #{exception.message}"
    status = exception.status || :service_unavailable
    
    respond_to do |format|
      format.html do
        flash.now[:alert] = exception.message
        render 'errors/service_unavailable', status: status
      end
      format.json do
        render json: { error: exception.message }, status: status
      end
    end
  end

  def render_error_page
    respond_to do |format|
      format.html { render "errors/service_unavailable", status: :service_unavailable }
      format.json { render json: { error: flash.now[:alert] }, status: :service_unavailable }
    end
  end
end
