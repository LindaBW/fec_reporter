$header_record = "HDRFEC8.1fec_reporter0.0"
$cover_record = "F3XNC00000000Make Your Laws PAC, Inc. (MYL PAC) 122 Pinecrest RdDurhamNC277055183Q12014010120140331SaiSai20140414"

module FecReporter
  
  class Filing
    
    def save
      File.open('reports/myl414.fec', 'w') do |file|
        file.puts $header_record
        file.puts $cover_record
      end
    end
  end
end


if __FILE__ == $0
  filing = FecReporter::Filing.new
  filing.save
end
