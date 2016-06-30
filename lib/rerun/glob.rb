# based on http://cpan.uwinnipeg.ca/htdocs/Text-Glob/Text/Glob.pm.html#glob_to_regex_string-

# todo: release as separate gem
#
module Rerun
  class Glob
    START_OF_FILENAME = '(\A|\/)'  # beginning of string or a slash
    END_OF_STRING = '\z'
    CONVERSION_TABLE = {
      "**" => "([^/]+/)*",
      "*" => ".*",
      "?" => ".",
      "." => "\\.",
      "{" => "(",
      "}" => -> visited, enumerator { nested?(visited) ? ")" : "}" },
      "," => -> visited, enumerator { nested?(visited) ? "|" : "," },
      "\\" => -> visited, enumerator { "\\#{enumerator.next}" }
    }

    def self.glob_to_regexp(glob)
      Glob.new(glob).to_regexp
    end

    def self.nested?(arr)
      unclosed_braces = arr.inject(0) { |count, char|
        if char == "{"
          count += 1
        elsif char == "}"
          count -= 1
        end
        count
      }
      unclosed_braces > 0
    end

    def initialize glob_string
      @glob_string = glob_string
    end

    def to_regexp_string
      chars = @glob_string.split('')
      chars = smoosh(chars)
      enumerator = chars.each

      visited, results = [], []

      loop do
        char = enumerator.next
        conversion = CONVERSION_TABLE.fetch(char, char)
        if conversion.is_a?(Proc)
          conversion = conversion.call(visited, enumerator)
        end
        results << conversion
        visited << char
      end
      START_OF_FILENAME + results.join + END_OF_STRING
    end

    def to_regexp
      Regexp.new(to_regexp_string)
    end

    def smoosh chars
      out = []
      until chars.empty?
        char = chars.shift
        if char == "*" and chars.first == "*"
          chars.shift
          chars.shift if chars.first == "/"
          out.push("**")
        else
          out.push(char)
        end
      end
      out
    end
  end
end
