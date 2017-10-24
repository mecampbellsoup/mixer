require 'rest-client'

# Jobcoin::Address interfaces with the address resource within the Jobcoin API.
# https://jobcoin.gemini.com/amiable/api#addresses-address-info
# GET /addresses/:address
class Jobcoin
  class Address
    def initialize(address)
      @address = address
    end

    # Get the balance for an address.
    def balance
      JSON.parse(response.body).fetch('balance')
    end

    # Get the of transactions for an address.
    def transactions
      JSON.parse(response.body).fetch('transactions')
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
