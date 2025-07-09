# frozen_string_literal: true

module OneRoster
  module Types
    class School
      attr_reader :uid, :name, :number, :tenant_id

      def initialize(attributes = {}, *)
        @uid      = attributes['sourcedId']
        @name     = attributes['name']
        @number   = attributes['identifier']
        @provider = 'oneroster'
        @tenant_id = attributes.dig("parent", "sourcedId")
      end
    end
  end
end
