require 'rails/generators'
require 'rails/generators/migration'

module BallotBox
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      
      desc "Create ballot_box migration"
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))      
      
      # copy migration files
      def create_migrations
        migration_template "migrate/create_votes.rb", File.join('db/migrate', "ballot_box_create_votes.rb")
      end
      
      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          current_time.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end
      
      def self.current_time
        @current_time ||= Time.now
        @current_time += 1.minute
      end
    end
  end
end
