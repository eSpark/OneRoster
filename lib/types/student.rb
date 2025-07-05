# frozen_string_literal: true

module OneRoster
  module Types
    class Student < Base
      attr_reader :uid,
                  :first_name,
                  :last_name,
                  :usename,
                  :provider,
                  :email,
                  :grades,
                  :school_id

      def initialize(attributes = {}, client: nil)
        @uid          = attributes['sourcedId']
        @first_name   = attributes['givenName']
        @last_name    = attributes['familyName']
        @status       = attributes['status']
        @email        = attributes['email']
        @username     = username(client)
        @provider     = 'oneroster'
        @grades       = attributes['grades']
        @school_id    = school_id_from(attributes)
      end

      def username(client = nil)
        username_source = client&.username_source

        @username ||= presence(username_from(username_source)) || default_username
      end

      def school_id_from(attributes)
        orgs = attributes.dig("orgs")
        return unless orgs && orgs.is_a?(Array)

        orgs.filter{ |org| org["type"] == "org"}.first&.dig("sourcedId")
      end

      def to_h
        {
          uid: @uid,
          first_name: @first_name,
          last_name: @last_name,
          username: @username,
          provider: @provider,
          email: @email,
          grades: @grades,
          school_id: @school_id
}
      end

      private

      def presence(field)
        field unless blank?(field)
      end

      def blank?(field)
        field.nil? || field == ''
      end

      def username_from(username_source)
        return unless presence(username_source)

        source = username_source(username_source)

        presence(instance_variable_get("@#{source}"))
      end

      # if the username_source is `sourcedId`, we want to return `uid`
      # so we can grab the right instance variable
      def username_source(source)
        case source
        when 'sourcedId' then 'uid'
        when 'username' then 'api_username'
        else
          source
        end
      end

      def default_username
        presence(@api_username) || presence(@email) || @uid
      end
    end
  end
end
