module Remi
  module DataTarget
    class Postgres
      include DataTarget

      def initialize(credentials:, table_name:, fields:, logger: Remi::Settings.logger)
        @credentials = credentials
        @table_name = table_name
        @fields = fields
        @logger = logger
      end

      def load
        return true if @loaded || df.size == 0

        @logger.info "Performing postgres load to table #{@table_name}"
        create_target_table
        load_target_table

        @loaded = true
      end


      def connection
        @connection ||= PG.connect(
          host:     @credentials[:host] || 'localhost',
          port:     @credentials[:port] || 5432,
          dbname:   @credentials[:dbname],
          user:     @credentials[:user] || `whoami`.chomp,
          password: @credentials[:password],
          sslmode:  @credentials[:sslmode] || 'allow'
        )
      end


      def fields_with_type_ddl
        @fields.map { |k,v| "#{k} #{v[:type]}" }.join(', ')
      end

      def create_target_table
        connection.exec <<-EOT
          CREATE TEMPORARY TABLE #{@table_name} (
            #{fields_with_type_ddl}
          )
        EOT
      end

      def load_target_table
        connection.copy_data "COPY #{@table_name} (#{@fields.keys.join(', ')}) FROM STDIN" do
          df.each(:row) do |row|
            row_str = @fields.keys.map do |field|
              field = row[field]
              case
              when field.respond_to?(:strftime)
                field.strftime('%Y-%m-%d %H:%M:%S')
              when field.respond_to?(:map)
                field.to_json.gsub("\t", '\t')
              when field.blank? && !field.nil?
                ''
              when field.nil?
                '\N'
              else
                field.to_s.gsub("\t", '\t')
              end
            end.join("\t")

            connection.put_copy_data row_str + "\n"
          end
        end
      end

    end
  end
end
