# app/errors/api_error.rb
class ApiError < StandardError
  attr_reader :status
  
  def initialize(message, status = :service_unavailable)
    super(message)
    @status = status
  end
end