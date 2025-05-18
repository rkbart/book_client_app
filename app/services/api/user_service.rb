module Api
  class UserService
    API_BASE_URL = "http://localhost:3000/api/v1/users".freeze

    class << self
      def all
        handle_response(HTTParty.get(API_BASE_URL))
      end

      def find(id)
        handle_response(HTTParty.get("#{API_BASE_URL}/#{id}"))
      end

      def create(params)
        handle_response(
          HTTParty.post(
            API_BASE_URL,
            body: { user: params }.to_json,
            headers: json_headers
          )
        )
      end

      def update(id, params)
        handle_response(
          HTTParty.patch(
            "#{API_BASE_URL}/#{id}",
            body: { user: params }.to_json,
            headers: json_headers
          )
        )
      end

      def destroy(id)
        handle_response(
          HTTParty.delete("#{API_BASE_URL}/#{id}")
        )
      end

      def user_books(user_id)
        handle_response(
          HTTParty.get("#{API_BASE_URL}/#{user_id}/books")
        )
      end

      private

      def json_headers
        {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      end

      def handle_response(response)
        if response.success?
          response.parsed_response || {}
        else
          error = response.parsed_response["error"] || 
                  response.parsed_response["errors"] || 
                  "API request failed with status #{response.code}"
          raise ApiError.new(error, response.code)  # Using ApiError directly
        end
      end
    end
  end
end
