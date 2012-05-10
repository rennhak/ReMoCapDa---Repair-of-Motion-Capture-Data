$:.unshift(File.dirname(__FILE__) + '/../../lib')


# require 'cucumber/rake/task'


#require 'cucumber/rake/task'
require 'rspec'
require 'rspec/core/rake_task'

#require 'metric_fu'
 

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/*_spec.rb'
  # spec.rspec_opts = ['--backtrace -c --format doc']
  spec.rspec_opts = ['-c --format doc']
end

task :default => :spec

Dir[ "spec/*_spec.rb" ].each do |s|
  filename = File.basename( s )
  basename = filename.gsub( "_spec.rb", "" )

  RSpec::Core::RakeTask.new( basename.downcase.to_sym ) do |spec|
      spec.pattern = s
      spec.rspec_opts = ['-c --format doc']
  end
end


# task :default => [:verify_rcov]
# task :verify_rcov => [:spec, :stories]

# desc "Run all specs"
# Spec::Rake::SpecTask.new do |t|
#   t.spec_files = FileList['spec/**/*_spec.rb']
#   t.spec_opts = ['--options', 'spec/spec.opts']
#   unless ENV['NO_RCOV']
#     t.rcov = true
#     t.rcov_dir = '../doc/coverage/coverage'
#     t.rcov_opts = ['--exclude', 'spec\/spec,bin\/spec,examples,\/var\/lib\/gems,\/Library\/Ruby,\.autotest']
#   end
# end
# 
# 
# desc "Run all stories"
# task :stories do
#   html = 'story_server/prototype/rspec_stories.html'
#   ruby "stories/all.rb --colour --format plain --format html:#{html}"
#   unless IO.read(html) =~ /<span class="param">/m
#     raise 'highlighted parameters are broken in story HTML'
#   end
# end
# 
# 
# desc "Run all specs and store html output in doc/output/report.html"
# Spec::Rake::SpecTask.new('spec_html') do |t|
#   t.spec_files = FileList['spec/**/*_spec.rb', '../../RSpec.tmbundle/Support/spec/*_spec.rb']
#   t.spec_opts = ['--format html:../doc/output/report.html','--backtrace']
# end
# 

def egrep(pattern)
  Dir['**/*.rb'].each do |fn|
    count = 0
    open(fn) do |f|
      while line = f.gets
        count += 1
        if line =~ pattern
          puts "#{fn}:#{count}:#{line}"
        end
      end
    end
  end
end


desc "Look for TODO and FIXME tags in the code"
task :todo do
    egrep /(FIXME|TODO|TBD)/
end



# desc "Default Task - Run cucumber and rspec with rcov"
# task :all => [ "rcov:all" ]



#desc "Run Cucumber"
#Cucumber::Rake::Task.new
#
## Include RCOV
#namespace :rcov do # {{{
#
#  desc "Run Cucumber Features"
#  Cucumber::Rake::Task.new( :cucumber ) do |t|
#    t.rcov = true
#    t.rcov_opts = %w{--aggregate coverage.info}
#    t.rcov_opts << %[-o "coverage"]
#    t.cucumber_opts = %w{--format pretty}
#  end
#
#
#  Spec::Rake::SpecTask.new(:rspec) do |t|
#    t.spec_files = FileList['spec/**/*_spec.rb']
#    t.rcov = true
#    #t.rcov_opts = lambda do
#    #  IO.readlines("#{RAILS_ROOT}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
#    #end
#  end
#
#  desc "Run both specs and features to generate aggregated coverage"
#  task :all do |t|
#    rm "coverage.info" if File.exist?("coverage.info")
#    Rake::Task['rcov:rspec'].invoke
#    Rake::Task["rcov:cucumber"].invoke
#    # Rake::Task["flog"].invoke
#    # Rake::Task["flay"].invoke
#  end
#
#
#end # of namespace :rcov }}}
#
desc "Clean up temporary data"
task :clean do |t|
  `rm coverage.info` if( File.exists?( "coverage.info" ) )
  `rm -rf coverage`  if( File.exists?( "coverage" ) )
  `rm -rf .yardoc`   if( File.exists?( ".yardoc" ) )
  Dir.chdir( "doc" ) do 
    `rm -rf yardoc`  if( File.exists?( "yardoc" ) )
  end
end

desc "Flog the code"
task :flog do |t|
  files = Dir["**/*.rb"]
  files.collect! { |f| (  f =~ %r{archive|features|spec}i ) ? ( next ) : ( f )  }
  files.compact!
  files.each do |f|
    puts ""
    puts "#######"
    puts "# #{f}"
    puts "################"
    system "flog #{f}"
    puts ""
  end
end

desc "Flay the code"
task :flay do |t|
  files = Dir["**/*.rb"]
  files.collect! { |f| (  f =~ %r{archive|features|spec}i ) ? ( next ) : ( f )  }
  files.compact!
  files.each do |f|
    puts ""
    puts "#######"
    puts "# #{f}"
    puts "################"
    system "flay #{f}"
    puts ""
  end
end

desc "Generate Yardoc documentation"
task :yardoc do |t|
  `yardoc -o doc/yardoc`
end


desc "Generate proper README via m4"
task :readme do |t|
  sh "m4 m4/README.m4 > README"
end


# cucumber --format usage
# cucover
# autotest
# spork
# testjour
#   distribute over cores or machines


