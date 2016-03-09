require 'remi_spec'

describe Extractor::SftpFile do
  before do
    now = Time.new

    example_files = [
      { name: "ApplicantsA-9.csv", createtime: now - 10.minutes },
      { name: "ApplicantsA-3.csv", createtime: now - 5.minutes },
      { name: "ApplicantsA-5.csv", createtime: now - 1.minutes },
      { name: "ApplicantsB-7.csv", createtime: now - 10.minutes },
      { name: "ApplicantsB-6.csv", createtime: now - 5.minutes },
      { name: "ApplicantsB-2.csv", createtime: now - 1.minutes },
      { name: "ApplicantsB-2.txt", createtime: now - 0.minutes },
      { name: "Apples.csv", createtime: now - 1.minutes },
    ]

    allow_any_instance_of(Extractor::SftpFile).to receive(:all_entries) do
      example_files.map do |file|
        Net::SFTP::Protocol::V04::Name.new(
          file[:name],
          Net::SFTP::Protocol::V04::Attributes.new(createtime: file[:createtime])
        )
      end
    end

    @params = { credentials: nil }
  end

  let(:sftpfile) { Extractor::SftpFile.new(**@params) }




  context 'extracting all files matching a pattern' do
    before do
      @params[:remote_file] = /ApplicantsA-\d+\.csv/
    end

    it 'does not extract non-matching files' do
      expect(sftpfile.to_download.map(&:name)).not_to include "Apples.csv"
    end

    it 'extracts all matching files' do
      expect(sftpfile.to_download.map(&:name)).to match_array([
       "ApplicantsA-9.csv",
       "ApplicantsA-3.csv",
       "ApplicantsA-5.csv"
      ])
    end
  end


  context 'extracting only the most recent matching a pattern' do
    before do
      @params.merge!({
        remote_file: /ApplicantsA-\d+\.csv/,
        most_recent_only: true
      })
    end

    it 'extracts only the most recent matching file' do
      expect(sftpfile.to_download.map(&:name)).to match_array([
       "ApplicantsA-5.csv"
      ])
    end

    context 'using filename instead of createtime' do
      before do
        @params[:most_recent_by] = :filename
      end

      it 'extracts only the most recent matching file' do
        expect(sftpfile.to_download.map(&:name)).to match_array([
         "ApplicantsA-9.csv"
        ])
      end
    end
  end


  context 'extracting files matching a pattern with a by group' do
    before do
      @params.merge!({
        credentials: nil,
        remote_file: /^Applicants(A|B)-\d+\.csv/,
        group_by: /^Applicants(A|B)/
      })
    end

    it 'extracts the most recent file that matches a particular regex' do
      expect(sftpfile.to_download.map(&:name)).to match_array([
       "ApplicantsA-5.csv",
       "ApplicantsB-2.csv"
      ])
    end

    context 'with a minimally selective pre-filter' do
      before do
        @params[:remote_file] = /^Applicants/
      end

      it 'extracts the most recent file that matches a particular regex' do
        expect(sftpfile.to_download.map(&:name)).to match_array([
         "ApplicantsA-5.csv",
         "ApplicantsB-2.txt"
        ])
      end
    end

    context 'using filename instead of createtime' do
      before do
        @params[:most_recent_by] = :filename
      end

      it 'extracts only the most recent matching file' do
        expect(sftpfile.to_download.map(&:name)).to match_array([
         "ApplicantsA-9.csv",
         "ApplicantsB-7.csv"
        ])
      end
    end

  end
end
