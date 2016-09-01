require 'remi_spec'

describe Extractor::FileSystem do
  before do
    now = Time.new

    example_files = [
      { pathname: "pdir/ApplicantsA-9.csv",      create_time: now - 10.minutes },
      { pathname: "pdir/ApplicantsA-3.csv",      create_time: now - 5.minutes  },
      { pathname: "pdir/ApplicantsA-5.csv",      create_time: now - 1.minutes  },
      { pathname: "pdir/ApplicantsB-7.csv",      create_time: now - 10.minutes },
      { pathname: "pdir/ApplicantsB-6.csv",      create_time: now - 5.minutes  },
      { pathname: "pdir/ApplicantsB-2.csv",      create_time: now - 1.minutes  },
      { pathname: "pdir/ApplicantsB-2.txt",      create_time: now - 0.minutes  },
      { pathname: "pdir/Apples.csv",             create_time: now - 1.minutes  },
      { pathname: "otherdir/ApplicantsA-11.csv", create_time: now - 1.minutes  },
    ]

    remote_path = 'pdir'
    allow_any_instance_of(Extractor::FileSystem).to receive(:all_entries) do
      example_files.map do |entry|
        Extractor::FileSystemEntry.new(
          pathname: entry[:pathname],
          create_time: entry[:create_time],
          modified_time: entry[:create_time]
        ) if Pathname.new(entry[:pathname]).dirname.to_s == remote_path
      end.compact
    end

    @params = { remote_path: remote_path }
  end

  let(:file_system) { Extractor::FileSystem.new(**@params) }



  context 'extracting all files matching a pattern' do
    before do
      @params.merge!({
        pattern: /ApplicantsA-\d+\.csv/
      })
    end

    it 'does not extract non-matching files' do
      expect(file_system.entries.map(&:name)).not_to include "Apples.csv"
    end

    it 'does not extract files not in the target directory' do
      expect(file_system.entries.map(&:name)).not_to include "ApplicantsA-11.csv"
    end

    it 'extracts all matching files' do
      expect(file_system.entries.map(&:name)).to match_array([
       "ApplicantsA-9.csv",
       "ApplicantsA-3.csv",
       "ApplicantsA-5.csv"
      ])
    end
  end


  context 'extracting only the most recent matching a pattern' do
    before do
      @params.merge!({
        pattern: /ApplicantsA-\d+\.csv/,
        most_recent_only: true
      })
    end

    it 'extracts only the most recent matching file' do
      expect(file_system.entries.map(&:name)).to match_array([
       "ApplicantsA-5.csv"
      ])
    end

    context 'using filename instead of createtime' do
      before do
        @params.merge!({
          most_recent_by: :name
        })
      end

      it 'extracts only the most recent matching file' do
        expect(file_system.entries.map(&:name)).to match_array([
         "ApplicantsA-9.csv"
        ])
      end
    end
  end


  context 'extracting the most recent file by create time' do
    before do
      @params.merge!({
         most_recent_within_n: 1.hour,
         most_recent_only: true
      })
    end

    it 'extracts the files within n hours of creation' do
      expect(file_system.entries.map(&:name)).to match_array([
        "ApplicantsB-2.txt"
      ])
    end
  end

  context 'extracting all recent files by create time' do
    before do
      @params.merge!({
         created_within: 0.02.hours,
         most_recent_only: false
      })
    end

    it 'extracts the files within n hours of creation' do
      puts @params
      expect(file_system.entries.map(&:name)).to match_array([
        "Apples.csv",
        "ApplicantsA-5.csv",
        "ApplicantsB-2.csv",
        "ApplicantsB-2.txt"
      ])
    end
  end

  context 'extracting files matching a pattern with a by group' do
    before do
      @params.merge!({
        pattern: /^Applicants(A|B)-\d+\.csv/,
        group_by: /^Applicants(A|B)/
      })
    end

    it 'extracts the most recent file that matches a particular regex' do
      expect(file_system.entries.map(&:name)).to match_array([
       "ApplicantsA-5.csv",
       "ApplicantsB-2.csv"
      ])
    end

    context 'with a minimally selective pre-filter' do
      before do
        @params.merge!({
          pattern: /^Applicants/
        })
      end

      it 'extracts the most recent file that matches a particular regex' do
        expect(file_system.entries.map(&:name)).to match_array([
         "ApplicantsA-5.csv",
         "ApplicantsB-2.txt"
        ])
      end
    end

    context 'using filename instead of createtime' do
      before do
        @params.merge!({
          most_recent_by: :name
        })
      end

      it 'extracts only the most recent matching file' do
        expect(file_system.entries.map(&:name)).to match_array([
         "ApplicantsA-9.csv",
         "ApplicantsB-7.csv"
        ])
      end
    end

  end
end
