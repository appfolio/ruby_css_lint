require 'tempfile'

if defined?(Rails)
  require 'rake'
  module RubyCssLint
    class Railtie < Rails::Railtie
      extend Rake::DSL
      rake_tasks do
        namespace :css_lint do

          task :run => :environment do |t|
            RubyCssLint::construct_js_and_run_rhino(RubyCssLint::location_of_css_files(Rails.root))
          end

          task :ci => :environment do |t|
            fail if RubyCssLint::construct_js_and_run_rhino(RubyCssLint::location_of_css_files(Rails.root)) > 0
          end

          task :dump_to_file => :environment do |t|
            RubyCssLint::construct_js_and_run_rhino(RubyCssLint::location_of_css_files(Rails.root), 'css_lint_output.txt')
          end

          task :generate_config => :environment do |t|
            File.open("#{Rails.root.to_s}/config/initializers/css_lint.rb", "w") do |filehandle|
              filehandle.puts <<-CSS_LINT_INIT
module RubyCssLint
#{RubyCssLint::DEFAULT_CONFIG}
end
CSS_LINT_INIT
              
            end
            
          end

        end
      end
    end
  end
end

module RubyCssLint
  WARNING = 1
  ERROR = 2
  DONT_CARE = nil
  
  DEFAULT_CONFIG = <<-CSS_LINT_DEFAULT
  def self.ruleset_classifications
    {
      "adjoining-classes" => RubyCssLint::WARNING,
      "box-model" => RubyCssLint::WARNING,
      "box-sizing" => RubyCssLint::WARNING,
      "compatible-vendor-prefixes" => RubyCssLint::WARNING,
      "display-property-grouping" => RubyCssLint::WARNING,
      "duplicate-background-images" => RubyCssLint::WARNING,
      "duplicate-properties" => RubyCssLint::WARNING,
      "empty-rules" => RubyCssLint::WARNING,
      "errors" => RubyCssLint::ERROR,
      "fallback-colors" => RubyCssLint::WARNING,
      "floats" => RubyCssLint::WARNING,
      "font-faces" => RubyCssLint::WARNING,
      "font-sizes" => RubyCssLint::WARNING,
      "gradients" => RubyCssLint::WARNING,
      "ids" => RubyCssLint::WARNING,
      "import" => RubyCssLint::WARNING,
      "important" => RubyCssLint::WARNING,
      "known-properties" => RubyCssLint::WARNING,
      "outline-none" => RubyCssLint::WARNING,
      "overqualified-elements" => RubyCssLint::WARNING,
      "qualified-headings" => RubyCssLint::WARNING,
      "regex-selectors" => RubyCssLint::WARNING,
      "rules-count" => RubyCssLint::WARNING,
      "shorthand" => RubyCssLint::WARNING,
      "star-property-hack" => RubyCssLint::WARNING,
      "text-indent" => RubyCssLint::WARNING,
      "underscore-property-hack" => RubyCssLint::WARNING,
      "unique-headings" => RubyCssLint::WARNING,
      "universal-selector" => RubyCssLint::WARNING,
      "unqualified-attributes" => RubyCssLint::WARNING,
      "vendor-prefix" => RubyCssLint::WARNING,
      "zero-units" => RubyCssLint::WARNING,
    }
  end

  def self.location_of_custom_rules(rails_root)
    []
  end

  def self.location_of_css_files(rails_root)
    [rails_root.to_s+"/public/assets/application.css"]
  end

CSS_LINT_DEFAULT
  
  self.class_eval(DEFAULT_CONFIG)
  
  
  def self.construct_error_and_warning_options
    rc = self.ruleset_classifications
    warnings = rc.keys.select{|k| rc[k] == RubyCssLint::WARNING}
    errors = rc.keys.select{|k| rc[k] == RubyCssLint::ERROR}
    result = " "
    result += "--warnings=#{warnings.join(',')} " if warnings.size > 0
    result += "--errors=#{errors.join(',')} " if errors.size > 0
    result
  end
  
  def self.construct_js_and_run_rhino(css_files, output_location = nil)
    css_files = css_files.join(" ") if css_files.is_a?(Array)
    
    Tempfile.open("csslint_temp_js") do |tempfile|
      tempfile.puts <<-HEADER
var CSSLint = (function(){      
HEADER
      tempfile.puts`cat #{list_of_js_files_to_compile_step_1}`
      tempfile.puts <<-FOOTER
    return CSSLint;
})();
FOOTER
      tempfile.puts`cat #{list_of_js_files_to_compile_step_2}`
      tempfile.flush
      return run_rhino_with_js_file(tempfile.path, css_files, output_location)
    end

    
  end
  
  def self.run_rhino_with_js_file(file, css_files, output_location = nil)
    rhino_jarfile = File.dirname(__FILE__) + "/../js.jar"
    command = "java -jar #{rhino_jarfile} #{file} #{construct_error_and_warning_options} #{css_files}"
    command += " > #{output_location}" if output_location
    result = `#{command}`
    puts result
    return $?.exitstatus
  end
  
  def self.list_of_js_files_to_compile_step_1
    css_lint_root_directory = File.dirname(__FILE__) + "/../csslint/"
    
    parserlib_location = css_lint_root_directory + "/lib/parserlib.js"
    csslint_main_location = css_lint_root_directory + "/src/core/CSSLint.js"
    other_core_files = `ls -d #{(css_lint_root_directory+"/src/core/*.js")} | grep -v CSSLint`.split(/\n/).join(" ")
    built_in_rules_file = css_lint_root_directory + "/src/rules/*.js"

    custom_rules_files = location_of_custom_rules(Rails.root).join(" ")

    formatters = css_lint_root_directory + "/src/formatters/*.js"
    
    [
      parserlib_location, 
      csslint_main_location, 
      other_core_files, 
      built_in_rules_file, 
      custom_rules_files, 
      formatters
    ].join(" ")
  end
  
  def self.list_of_js_files_to_compile_step_2
    css_lint_root_directory = File.dirname(__FILE__) + "/../csslint/"
    
    cli_common = css_lint_root_directory + "/src/cli/common.js"
    cli_rhino = css_lint_root_directory + "/src/cli/rhino.js"
    [
      cli_common,
      cli_rhino 
    ].join(" ")
  end
end


