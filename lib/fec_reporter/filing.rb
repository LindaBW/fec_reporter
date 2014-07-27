require 'money'

module FecReporter
  
  class Filing
    
    def initialize options = {}
      @fec_version = options[:fec_version] || 8.1
      @entity = options[:entity] || "Make Your Laws PAC, Inc. (MYL PAC)"
      # etc
    end

    def header_record
      "HDR\u001CFEC\u001C8.1\u001Cfec_reporter\u001C0.0"
    end

    def cover_record
      F3x.new.cover_record
    end

    def save
      File.open('reports/myl414.fec', 'w') do |file|
        file.puts header_record
        file.puts cover_record
        #schedules.each do {|sch| file.puts sch.record}
      end
    end
  end

  class F3x

    def initialize options = {}
      @fec_version = options[:fec_version] || 8.1
      @entity = options[:entity] || "Make Your Laws PAC, Inc. (MYL PAC)"
      @year = options[:year] || "2014"
      
      
      @entries = {:info =>{}, :A=>{}, :B=>{}}
      
      #The physical paper prompts in the info section, in the order they appear
      #The corresponding values, in this order, populate fields 1-22
      @lines_of_info = ['FORM TYPE', 'FILER COMMITTEE ID NUMBER', 'COMMITTEE NAME',
        'CHANGE OF ADDRESS', 'STREET 1', 'STREET 2', 'CITY', 'STATE', 'ZIP',
        'REPORT CODE', 'ELECTION CODE', 'DATE OF ELECTION', 'STATE OF ELECTION',
        'COVERAGE FROM DATE', 'COVERAGE THROUGH DATE', 'QUALIFIED COMMITTEE',
        'TREASURER LAST NAME', 'TREASURER FIRST NAME', 'TREASURER MIDDLE NAME',
        'TREASURER PREFIX', 'TREASURER SUFFIX', 'DATE SIGNED']
 
      @entries[:info]['FORM TYPE'] = options[:form_type] || "F3XN"
      @entries[:info]['FILER COMMITTEE ID NUMBER'] = options[:committee_id] || "C00529743"
      @entries[:info]['COMMITTEE NAME'] = options[:entity] || 
        "Make Your Laws PAC, Inc. (MYL PAC)"
      @entries[:info]['CHANGE OF ADDRESS'] = options[:change_addr?] || ""
      @entries[:info]['STREET 1'] = options[:street1] || "122 Pinecrest Rd"
      @entries[:info]['STREET 2'] = options[:street2] || ""
      @entries[:info]['CITY'] = options[:city] || "Durham"
      @entries[:info]['STATE'] = options[:state] || "NC"
      @entries[:info]['ZIP'] = options[:zip] || "277055183"
      @entries[:info]['REPORT CODE'] = options[:report_code] || "Q1"
      @entries[:info]['ELECTION CODE'] = options[:election_code] || ""
      @entries[:info]['DATE OF ELECTION'] = options[:election_date] || ""
      @entries[:info]['STATE OF ELECTION'] = options[:election_state] || ""
      @entries[:info]['COVERAGE FROM DATE'] = options[:coverage_from_date] || "20140101"
      @entries[:info]['COVERAGE THROUGH DATE'] = options[:coverage_thru_date] || "20140331"
      @entries[:info]['QUALIFIED COMMITTEE'] = options[:qualified_committee] || ""
      @entries[:info]['TREASURER LAST NAME'] = options[:treasurer_lastname] || "Sai"
      @entries[:info]['TREASURER FIRST NAME'] = options[:treasurer_firstname] || "Sai"
      @entries[:info]['TREASURER MIDDLE NAME'] = options[:treasurer_middlename] || ""
      @entries[:info]['TREASURER PREFIX'] = options[:treasurer_prefix] || ""
      @entries[:info]['TREASURER SUFFIX'] = options[:treasurer_suffix] || ""
      @entries[:info]['DATE SIGNED'] = options[:date_signed] || "20140414"
 
      
      #Auxiliary list for columns A and B
      @lines_in_both_columns = ['11ai','11aii','11aiii',
               '11b','11c','11d','12','13','14','15','16','17','18a',
               '18b','18c','19','20','21ai','21aii','21b','21c','22','23',
               '24','25','26','27','28a','28b','28c','28d','29',
               '30ai','30aii','30b','30c','31','32','33','34','35','36',
               '37','38']
               
      #The physical paper line numbers in column A, in the order they appear.
      #The corresponding values, in this order, populate fields 23-73
      @lines_of_column_a = ['6b','6c','6d','7','8','9','10'] + @lines_in_both_columns
      
      #The physical paper line numbers in column B, in the order they appear.
      #Yes, for some reason the FEC has included the fiscal year in Column B.
      #The corresponding values, in this order, populate fields 74-123
      @lines_of_column_b = ['6a','6a_year','6c','6d','7','8'] + @lines_in_both_columns
      
      #These lines initialize all the finiancial entries with $0.00 USD
      [@lines_of_column_a,@lines_of_column_b].zip([:A,:B]).each do |lines,col|
        lines.each do |line|
          @entries[col][line] = Money.new(0,"USD")
        end
      end
      #But because the fiscal year is included in Column B, we'd rather just set it so:
      @entries[:B]['6a_year'] = options[:year]
      
      fill_out_form
    end

    def fill_out_form
      @entries[:B]['6a'] = Money.new(74382,"USD")
      @entries[:A]['6b'] = Money.new(74382,"USD")
      @entries[:A]['15'] = Money.new(2800, "USD")
      @entries[:B]['15'] = Money.new(2800, "USD")
      @entries[:A]['21b'] = Money.new(51362, "USD")
      @entries[:B]['21b'] = Money.new(51362, "USD")
      do_the_math
    end

    def do_the_math
      [@entries[:A],@entries[:B]].each do |lines|
        lines['11aiii'] = lines['11ai'] + lines['11aii']
        lines['11d'] = lines['11aiii'] + lines['11b'] + lines['11c']
        lines['18c'] = lines['18a'] + lines['18b']
        lines['19'] = ['11d','12','13','14','15','16','17','18c'].reduce(Money.new(0,"USD")){|a,e| a+lines[e]}
        lines['20'] = lines['19'] - lines['18c']
        lines['21c'] = lines['21ai'] + lines['21aii'] + lines['21b']
        lines['28d'] = lines['28a'] + lines['28b'] + lines['28c']
        lines['30c'] = lines['30ai'] + lines['30aii'] + lines['30b']
        lines['31'] = ['21c','22','23','24','25','26','27','28d','29','30c'].reduce(Money.new(0,"USD")){|a,e| a+lines[e]}
        lines['32'] = lines['31'] - lines['21aii'] - lines ['30aii']
        lines['33'] = lines['11d']
        lines['34'] = lines['28d']
        lines['35'] = lines['33'] - lines['34']
        lines['36'] = lines['21ai'] + lines['21b']
        lines['37'] = lines['15']
        lines['38'] = lines['36'] - lines['37']
        #Carry these calculations to the summary part at the beginning
        lines['6c'] = lines['19']
        lines['7'] = lines['31']
      end
      
      @entries[:A]['6d'] = @entries[:A]['6b'] + @entries[:A]['6c']
      @entries[:B]['6d'] = @entries[:B]['6a'] + @entries[:A]['6c']
      [:A,:B].each do |col|
        @entries[col]['8'] = @entries[col]['6d'] - @entries[col]['7']
      end
    end
    
    def cover_record
      values_info = @lines_of_info.map{|x| @entries[:info][x].to_s}
      values_a = @lines_of_column_a.map{|x| @entries[:A][x].to_s}
      values_b = @lines_of_column_b.map{|x| @entries[:B][x].to_s}
      (values_info+values_a+values_b).join("\u001C")
    end
    
  end

end


if __FILE__ == $0
  filing = FecReporter::Filing.new
  filing.save
end
