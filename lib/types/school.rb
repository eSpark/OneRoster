# frozen_string_literal: true

module OneRoster
  module Types
    class Tenant
      attr_reader :uid, :name, :number, :tenant_id

      def initialize(attributes = {}, *)
        @uid      = attributes['sourcedId']
        @name     = attributes['name']
        @number   = attributes['identifier']
        @provider = 'oneroster'
        @tenant_id = tenant_id_from(attributes)
      end

      def tenant_id_from(attributes)
        orgs = attributes.dig("parent")
        return unless orgs && orgs.is_a?(Array)

        orgs.filter{ |org| org["type"] == "org"}.first&.dig("sourcedId")
      end
    end
  end
end
