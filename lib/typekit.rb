class TypekitImport

  def self.perform
    typekit = Typekit::Client.new(App.config.typekit_api_key)
    i = 1
    begin
      loop do
        library = typekit.library('full', page: i, per_page: 50)
        library.each do |f|
          family = typekit.family(f.id)
          r = ActiveRecord::Base.connection.execute("SELECT * FROM typefaces WHERE family_id='#{f.id}' LIMIT 1")
          if r.values.empty?
            family.variations.each do |v|
              ActiveRecord::Base.connection.execute("
                INSERT INTO typefaces (name, family_name, family_id, variation_id)
                VALUES(#{ActiveRecord::Base.connection.quote(v.name)},
                       #{ActiveRecord::Base.connection.quote(f.name)},
                       #{ActiveRecord::Base.connection.quote(f.id)},
                       #{ActiveRecord::Base.connection.quote(v.to_fvd)})
                ")
            end
          end
        end
        i += 1
      end
    rescue Exception => e
      puts e.message
      # we're done with the loop, we hit the max.
    end
  end

end
