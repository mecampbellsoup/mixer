require 'rest-client'

class Jobcoin

  class Address
    def initialize(address)
      @address = address
    end

    # Get the balance for an address.
    def balance
      response.fetch('balance')
    end

    # Get the of transactions for an address.
    def transactions
      response.fetch('transactions')
    end

    private

    def response
      @response ||= client.get("http://jobcoin.gemini.com/amiable/api/addresses/#{@address}")
    end

    def client
      RestClient
    end
  end
end
