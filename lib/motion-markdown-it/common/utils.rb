module MarkdownIt
  module Common
    module Utils

      # Merge multiple hashes
      #------------------------------------------------------------------------------
      def assign(obj, *args)
        raise(ArgumentError, "#{obj} must be a Hash") if !obj.is_a?(Hash)

        args.each do |source|
          next if source.nil?
          raise(ArgumentError, "#{source} must be a Hash") if !source.is_a?(Hash)
          obj.merge!(source)
        end

        return obj
      end

      # Remove element from array and put another array at those position.
      # Useful for some operations with tokens
      #------------------------------------------------------------------------------
      def arrayReplaceAt(src, pos, newElements)
        src[pos] = newElements
        src.flatten!(1)
        return src
      end

      #------------------------------------------------------------------------------
      def isValidEntityCode(c)
        # broken sequence
        return false if (c >= 0xD800 && c <= 0xDFFF)

        # never used
        return false if (c >= 0xFDD0 && c <= 0xFDEF)
        return false if ((c & 0xFFFF) === 0xFFFF || (c & 0xFFFF) === 0xFFFE)

        # control codes
        return false if (c >= 0x00 && c <= 0x08)
        return false if (c === 0x0B)
        return false if (c >= 0x0E && c <= 0x1F)
        return false if (c >= 0x7F && c <= 0x9F)

        # out of range
        return false if (c > 0x10FFFF)

        return true
      end

      #------------------------------------------------------------------------------
      def fromCodePoint(c)
        c.chr(Encoding::UTF_8)
      end

      #------------------------------------------------------------------------------
      def fromCharCode(c)
        c.chr
      end
      
      #------------------------------------------------------------------------------
      def charCodeAt(str, ch)
        str[ch].ord unless str[ch].nil?
      end

      UNESCAPE_MD_RE  = /\\([\!\"\#\$\%\&\'\(\)\*\+\,\-.\/:;<=>?@\[\\\]^_`{|}~])/

      ENTITY_RE       = /&([a-z#][a-z0-9]{1,31});/i
      UNESCAPE_ALL_RE = Regexp.new(UNESCAPE_MD_RE.source + '|' + ENTITY_RE.source, 'i')

      DIGITAL_ENTITY_TEST_RE = /^#((?:x[a-f0-9]{1,8}|[0-9]{1,8}))/i

      #------------------------------------------------------------------------------
      def replaceEntityPattern(match, name)
        code = 0

        return fromCodePoint(MarkdownIt::HTMLEntities::MAPPINGS[name]) if MarkdownIt::HTMLEntities::MAPPINGS[name]

        if (charCodeAt(name, 0) == 0x23 && DIGITAL_ENTITY_TEST_RE =~ name) # '#'
          code = name[1].downcase == 'x' ? name[2..-1].to_i(16) : name[1..-1].to_i
          if (isValidEntityCode(code))
            return fromCodePoint(code)
          end
        end

        return match
      end

      #------------------------------------------------------------------------------
      def unescapeMd(str)
        return str if !str.include?('\\')
        return str.gsub(UNESCAPE_MD_RE, '\1')
      end

      #------------------------------------------------------------------------------
      def unescapeAll(str)
        return str if (str.index('\\').nil? && str.index('&').nil?)

        return str.gsub(UNESCAPE_ALL_RE) do |match|
          next $1 if ($1)
          next replaceEntityPattern(match, $2)
        end
      end


      HTML_ESCAPE_TEST_RE     = /[&<>"]/
      HTML_ESCAPE_REPLACE_RE  = /[&<>"]/
      HTML_REPLACEMENTS       = {
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;',
        '"' => '&quot;'
      }

      #------------------------------------------------------------------------------
      def escapeHtml(str)
        if HTML_ESCAPE_TEST_RE =~ str
          return str.gsub(HTML_ESCAPE_REPLACE_RE, HTML_REPLACEMENTS)
        end
        return str
      end

      REGEXP_ESCAPE_RE = /[.?*+^$\[\]\\(){}|-]/

      #------------------------------------------------------------------------------
      def escapeRE(str)
        str.gsub(REGEXP_ESCAPE_RE) {|s| '\\' + s}
      end

      #------------------------------------------------------------------------------
      def isSpace(code)
        case code
        when 0x09,
             0x20
          return true
        end

        return false
      end

      # Zs (unicode class) || [\t\f\v\r\n]
      #------------------------------------------------------------------------------
      def isWhiteSpace(code)
        return true if (code >= 0x2000 && code <= 0x200A)
        case code
        when 0x09, # \t
             0x0A, # \n
             0x0B, # \v
             0x0C, # \f
             0x0D, # \r
             0x20,
             0xA0,
             0x1680,
             0x202F,
             0x205F,
             0x3000
          return true
        end
        return false
      end

      UNICODE_PUNCT_RE = UCMicro::Categories::P::REGEX

      # Currently without astral characters support.
      #------------------------------------------------------------------------------
      def isPunctChar(ch)
        return UNICODE_PUNCT_RE =~ ch
      end


      # Markdown ASCII punctuation characters.
      #
      # !, ", #, $, %, &, ', (, ), *, +, ,, -, ., /, :, ;, <, =, >, ?, @, [, \, ], ^, _, `, {, |, }, or ~
      # http://spec.commonmark.org/0.15/#ascii-punctuation-character
      #
      # Don't confuse with unicode punctuation !!! It lacks some chars in ascii range.
      #------------------------------------------------------------------------------
      def isMdAsciiPunct(ch)
        case ch
        when 0x21,  # !
             0x22,  # "
             0x23,  # #
             0x24,  # $
             0x25,  # %
             0x26,  # &
             0x27,  # '
             0x28,  # (
             0x29,  # )
             0x2A,  # *
             0x2B,  # +
             0x2C,  # ,
             0x2D,  # -
             0x2E,  # .
             0x2F,  # /
             0x3A,  # :
             0x3B,  # ;
             0x3C,  # <
             0x3D,  # =
             0x3E,  # >
             0x3F,  # ?
             0x40,  # @
             0x5B,  # [
             0x5C,  # \
             0x5D,  # ]
             0x5E,  # ^
             0x5F,  # _
             0x60,  # `
             0x7B,  # {
             0x7C,  # |
             0x7D,  # }
             0x7E   # ~
          return true
        else
          return false
        end
      end

      # Hepler to unify [reference labels].
      #------------------------------------------------------------------------------
      def normalizeReference(str)
        # use .toUpperCase() instead of .toLowerCase()
        # here to avoid a conflict with Object.prototype
        # members (most notably, `__proto__`)
        return str.strip.gsub(/\s+/, ' ').upcase
      end
    end
  end
end