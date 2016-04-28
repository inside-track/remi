=begin

this is probably mostly about data subjects


calling fields on the data subject should return only the fields defined, even if there
are additional fields on the dataframe

dataframe metadata is merged into field metadata, always with a preference for field metadata

metadata propagates through 1:1 STTMs

metadata propagates through intermediate dataframes that are not data subjects


    puts '---- ROUTE 1 - direct -----'
    out_activity.df = Remi::DataFrame.create(:daru, [], order: out_activity.fields.keys)#, index: in_activity.df.index)
    Remi::SourceToTargetMap.apply(in_activity.df, out_activity.df) do
#      map source(:activity_id, :student_id) .target(:activity_id, :student_id)
      map source(:activity_id) .target(:activity_id)
        .transform(->(v) { "-#{v}-" })
# enforce types needs to be based on the "fields" for the target
# I might have to convert any Daru Dataframe to Remi dataframes in the STTM

#        .transform(Remi::Transform[:enforce_types].(on_error: :ignore))

      map source(:student_id) .target(:student_id)
      map source(:student_dob) .target(:student_dob)
    end


    puts "out_activity.fields: #{out_activity.fields}"
    puts "out_activity.df metadata: #{out_activity.df.vector_metadata}"
    out_activity.df = out_activity.df[*(out_activity.fields.keys)]
    puts "out_activity.fields: #{out_activity.fields}"
    puts "out_activity.df metadata: #{out_activity.df.vector_metadata}"
    IRuby.display out_activity.df, type: 'text/html'


    puts '---- ROUTE 2 - via work_df -----'
    work_df = Remi::DataFrame.create(:daru, [], order: out_activity.fields.keys)#, index: in_activity.df.index)
    Remi::SourceToTargetMap.apply(in_activity.df, work_df) do
      map source(:activity_id) .target(:activity_id)
#        .transform(Remi::Transform[:enforce_types].(on_error: :ignore))

      map source(:student_id) .target(:student_id)
      map source(:student_dob) .target(:student_dob)
    end

    IRuby.display work_df, type: 'text/html'
    puts "work_df metadata: #{work_df.vector_metadata}"

    puts "out_activity.fields metadata: #{out_activity.fields}"
    puts "out_activity.df metadata: #{out_activity.df.vector_metadata}"
    puts "work_df is a #{work_df.class}"
    out_activity.df = work_df#[*out_activity.fields.keys]
    puts "out_activity.fields metadata: #{out_activity.fields}"
    puts "out_activity.df metadata: #{out_activity.df.vector_metadata}"
    IRuby.display out_activity.df, type: 'text/html'


=end
