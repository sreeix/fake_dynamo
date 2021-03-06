require 'sinatra/base'

module FakeDynamo
  class Server < Sinatra::Base

    set :show_exceptions, false

    post '/' do
      status = 200
      content_type 'application/x-amz-json-1.0'
      begin
        data = JSON.parse(request.body.read)
        operation = extract_operation(request.env)
        puts "operation #{operation}"
        puts "data"
        pp data
        response = db.process(operation, data)
      rescue Error => e
        response, status = e.response, e.status
      end
      puts "response"
      pp response
      [status, response.to_json]
    end

    def db
      DB.instance
    end

    def extract_operation(env)
      if env['HTTP_X_AMZ_TARGET'] =~ /DynamoDB_\d+\.([a-zA-z]+)/
        $1
      else
        raise UnknownOperationException
      end
    end
  end
end
