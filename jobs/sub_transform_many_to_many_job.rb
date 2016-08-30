require_relative 'all_jobs_shared'

class SharedManyToManyTransforms < Remi::Job
  sub_transform :unique_values do
    source :fact, [:id]
    source :dimension, [:id, :beer, :style]
    target :unique_beers, [:beer, :count]
    target :unique_styles, [:style, :count]

    flat_df = fact.df.join(dimension.df, on: [:id], how: :left)

    unique_beers.df = flat_df.group_by([:beer]).size.detach_index
    unique_beers.df.rename_vectors({ :index => :beer, :values => :count })

    unique_styles.df = flat_df.group_by([:style]).size.detach_index
    unique_styles.df.rename_vectors({ :index => :style, :values => :count })
  end
end

class SubTransformManyToManyJob < Remi::Job
  source :beer_fact do
    fields({ :fact_sk => {}, :beer_sk => {} })
  end

  source :beer_dim do
    fields({ :beer_sk => {}, :name => {}, :style => {} })
  end

  target :beer_count do
    fields({ :name => {}, :count => {} })
  end

  target :style_count do
    fields({ :style => {}, :count => {} })
  end

  transform :main do
    import SharedManyToManyTransforms.new.unique_values do
      map_source_fields :beer_fact, :fact, { :beer_sk => :id }
      map_source_fields :beer_dim, :dimension, { :beer_sk => :id, :name => :beer, :style => :style }

      map_target_fields :unique_beers, :beer_count, { :beer => :name, :count => :count }
      map_target_fields :unique_styles, :style_count, { :style => :style, :count => :count }
    end
  end
end
