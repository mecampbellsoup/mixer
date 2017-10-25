require 'rest-client'

class Jobcoin
  API_URI = "http://jobcoin.gemini.com/amiable/api".freeze

  class << self
    def transactions
      Jobcoin::Transaction
    end
  end

  # Jobcoin::Transaction interfaces with the transaction resource in the Jobcoin API.
  # GET /transactions  -> fetch all Jobcoin transactions
  # POST /transactions -> create a new Jobcoin transaction
  class Transaction
    class << self
      def create(from:, to:, amount:)
        transaction_params = { fromAddress: from, toAddress: to, amount: amount }

        response = begin
          client.post("#{API_URI}/transactions", transaction_params, {})
        rescue RestClient::ExceptionWithResponse => e
          e.response
        end

        response.code == 200
      end

      private

      def client
        RestClient
      end
    end
  end

  # Jobcoin::Address interfaces with the address resource within the Jobcoin API.
  # https://jobcoin.gemini.com/amiable/api#addresses-address-info
  # GET /addresses/:address
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
      @response ||= client.get("#{API_URI}/addresses/#{@address}")
    end

    def client
      RestClient
    end
  end
end
