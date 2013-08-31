require_relative "config"

namespace :db do
  desc "Create all necessary tables"
  task :setup do
    Rake::Task["db:create_tables"].invoke
  end

  desc "Create tables"
  task :create_tables do 
    ConfigData[:tables].each do |table_name, fields|
      DB.create_table table_name do
        primary_key :id

        fields.each do |name, params|
          if params.empty? 
            String(name) 
          else
            column(name, params[:type], default: params[:default])
          end
        end
      end
    end
  end

  desc "Drop tables"
  task :drop_tables do 
    ConfigData[:tables].keys.each{|name| DB.drop_table name }
  end
end

namespace :iterations do 
  desc "Make emls iteration"
  task :emls do 
    Emls.new.save
  end
end
