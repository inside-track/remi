module Remi
  class Dataview
    include Log
    
    def initialize
      @chart = nil
      @tpl = nil
    end


    def create_table
      data_table = GoogleVisualr::DataTable.new

      # Add Column Headers
      data_table.new_column('string', 'Year' )
      data_table.new_column('number', 'Sales')
      data_table.new_column('number', 'Expenses')

      data_table = GoogleVisualr::DataTable.new
      data_table.new_column('string'  , 'Name')
      data_table.new_column('number'  , 'Salary')
      data_table.new_column('boolean' , 'Full Time Employee')
      data_table.add_rows(4)
      data_table.set_cell(0, 0, 'Mike'  )
      data_table.set_cell(0, 1, {:v => 10000, :f => '$10,000'})
      data_table.set_cell(0, 2, true  )
      data_table.set_cell(1, 0, 'Jim'   )
      data_table.set_cell(1, 1, {:v => 8000 , :f => '$8,000' })
      data_table.set_cell(1, 2, false )
      data_table.set_cell(2, 0, 'Alice' )
      data_table.set_cell(2, 1, {:v => 12500, :f => '$12,500'})
      data_table.set_cell(2, 2, true  )
      data_table.set_cell(3, 0, 'Bob'   )
      data_table.set_cell(3, 1, {:v => 7000 , :f => '$7,000' })
      data_table.set_cell(3, 2, true  )

      opts   = { :width => 600, :showRowNumber => true }
      @chart = GoogleVisualr::Interactive::Table.new(data_table, opts)
      puts "Creating chart #{@chart}"
    end



    def table_tpl
      @tpl = ERB.new <<-EOF #.unindent
      <!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>
      <html xmlns='http://www.w3.org/1999/xhtml'>
        <head>
          <meta http-equiv='content-type' content='text/html; charset=utf-8'/>
          <title>
            Google Visualization API Sample
          </title>
          <script src='https://www.google.com/jsapi'></script>

            <%= @chart.to_js('table')%>

        </head>
        <body>
          <div id='table' style='height: 400px; width: 400px;'></div>
        </body>
       </html>
      EOF
    end


    def view_table
      unless File.directory?(RemiConfig.work_dirname)
        FileUtils.mkdir_p(RemiConfig.work_dirname)
      end

      viewdata_fullpath = File.join(RemiConfig.work_dirname,"visualr.html");
      File.open(viewdata_fullpath,'w') do |f|
        f.write table_tpl.result(binding)
      end

      Launchy.open(viewdata_fullpath)
    end

  end
end
