# typed: strict
# frozen_string_literal: true

require "addressable"
require "utils/curl"

module Homebrew
  # Helper module for querying Algolia.
  #
  # @api private
  module Algolia
    class APIError < RuntimeError; end

    extend T::Sig

    APPLICATION_ID = "BH4D9OD16A"
    private_constant :APPLICATION_ID

    API_KEY = "a57ef92bf2adfae863a201ee43d6b5a1"
    private_constant :API_KEY

    INDEX = "brew_all"
    private_constant :INDEX

    URL_TEMPLATE = T.let(Addressable::Template.new("https://#{APPLICATION_ID.downcase}-dsn.algolia.net/1/{+endpoint}{?query*}")
                                              .freeze, Addressable::Template)
    private_constant :URL_TEMPLATE

    sig {
      params(
        query:                  String,
        filters:                String,
        searchable_attributes:  T::Array[String],
        attributes_to_retrieve: T::Array[String],
        limit:                  Integer,
      ).returns(String)
    }
    def self.search(query, filters: "", searchable_attributes: [], attributes_to_retrieve: [], limit: 100)
      params = {
        query:                        query,
        filters:                      filters,
        attributesToRetrieve:         attributes_to_retrieve,
        restrictSearchableAttributes: searchable_attributes,
        hitsPerPage:                  limit,
        typoTolerance:                "strict",
      }.compact_blank

      params[:attributesToHighlight] = params[:attributesToSnippet] = []

      params_string = params.map do |key, value|
        value = if value.is_a?(Array)
          value.join(",")
        else
          value.to_s
        end

        "#{key}=#{ERB::Util.url_encode(value)}"
      end.join("&")

      api_query("indexes/#{INDEX}/query", method: :POST, data: { params: params_string }).fetch("hits")
    end

    sig {
      params(
        endpoint: String,
        method:   Symbol,
        data:     T.nilable(T::Hash[String, String]),
      ).returns(T::Hash[String, T.untyped])
    }
    private_class_method def self.api_query(endpoint, method: :GET, data: nil)
      url = URL_TEMPLATE.partial_expand(endpoint: endpoint)

      args = [
        "--fail",
        "--request", method.to_s,
        "--header", "X-Algolia-Application-Id: #{APPLICATION_ID}",
        "--header", "X-Algolia-API-Key: #{API_KEY}"
      ]
      if data.present?
        if method == :GET
          url = url.partial_expand(query: data)
        else
          args << "--header" << "Content-Type: application/json; charset=UTF-8"
          args << "--data-binary" << data.to_json
        end
      end

      result = curl_output(url.expand({}).to_s, *args)

      raise APIError, "Search query failed." unless result.success?

      JSON.parse(result.stdout)
    end
  end
end
