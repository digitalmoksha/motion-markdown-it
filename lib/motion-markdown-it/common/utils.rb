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
        return [].concat([src.slice(0...pos), newElements, src.slice_to_end(pos + 1)])
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


      UNESCAPE_MD_RE  = /\\([\!\"\#\$\%\&\'\(\)\*\+\,\-.\/:;<=>?@\[\\\]^_`{|}~])/

      ENTITY_RE       = /&([a-z#][a-z0-9]{1,31});/i
      UNESCAPE_ALL_RE = Regexp.new(UNESCAPE_MD_RE.source + '|' + ENTITY_RE.source, 'i')

      DIGITAL_ENTITY_TEST_RE = /^#((?:x[a-f0-9]{1,8}|[0-9]{1,8}))/i

      #------------------------------------------------------------------------------
      def replaceEntityPattern(match, name)
        code = 0

        return HTMLEntities::MAPPINGS[name].chr(Encoding::UTF_8) if HTMLEntities::MAPPINGS[name]

        if (name.charCodeAt(0) == 0x23 && DIGITAL_ENTITY_TEST_RE =~ name) # '#'
          code = name[1].downcase == 'x' ? name.slice_to_end(2).to_i(16) : name.slice_to_end(1).to_i
          if (isValidEntityCode(code))
            return fromCodePoint(code)
          end
        end

        return match
      end

      # not used
      #------------------------------------------------------------------------------
      # def replaceEntities(str)
      #   return str if str.index('&').nil?
      #   return str.gsub(ENTITY_RE, replaceEntityPattern)
      # end

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

      # from file uc.micro/categories/P/regex in github project
      # https://github.com/markdown-it/uc.micro
      # UNICODE_PUNCT_RE = /[!-#%-\*,-\/:;\?@\[-\]_\{\}\xA1\xA7\xAB\xB6\xB7\xBB\xBF\u037E\u0387\u055A-\u055F\u0589\u058A\u05BE\u05C0\u05C3\u05C6\u05F3\u05F4\u0609\u060A\u060C\u060D\u061B\u061E\u061F\u066A-\u066D\u06D4\u0700-\u070D\u07F7-\u07F9\u0830-\u083E\u085E\u0964\u0965\u0970\u0AF0\u0DF4\u0E4F\u0E5A\u0E5B\u0F04-\u0F12\u0F14\u0F3A-\u0F3D\u0F85\u0FD0-\u0FD4\u0FD9\u0FDA\u104A-\u104F\u10FB\u1360-\u1368\u1400\u166D\u166E\u169B\u169C\u16EB-\u16ED\u1735\u1736\u17D4-\u17D6\u17D8-\u17DA\u1800-\u180A\u1944\u1945\u1A1E\u1A1F\u1AA0-\u1AA6\u1AA8-\u1AAD\u1B5A-\u1B60\u1BFC-\u1BFF\u1C3B-\u1C3F\u1C7E\u1C7F\u1CC0-\u1CC7\u1CD3\u2010-\u2027\u2030-\u2043\u2045-\u2051\u2053-\u205E\u207D\u207E\u208D\u208E\u2308-\u230B\u2329\u232A\u2768-\u2775\u27C5\u27C6\u27E6-\u27EF\u2983-\u2998\u29D8-\u29DB\u29FC\u29FD\u2CF9-\u2CFC\u2CFE\u2CFF\u2D70\u2E00-\u2E2E\u2E30-\u2E42\u3001-\u3003\u3008-\u3011\u3014-\u301F\u3030\u303D\u30A0\u30FB\uA4FE\uA4FF\uA60D-\uA60F\uA673\uA67E\uA6F2-\uA6F7\uA874-\uA877\uA8CE\uA8CF\uA8F8-\uA8FA\uA92E\uA92F\uA95F\uA9C1-\uA9CD\uA9DE\uA9DF\uAA5C-\uAA5F\uAADE\uAADF\uAAF0\uAAF1\uABEB\uFD3E\uFD3F\uFE10-\uFE19\uFE30-\uFE52\uFE54-\uFE61\uFE63\uFE68\uFE6A\uFE6B\uFF01-\uFF03\uFF05-\uFF0A\uFF0C-\uFF0F\uFF1A\uFF1B\uFF1F\uFF20\uFF3B-\uFF3D\uFF3F\uFF5B\uFF5D\uFF5F-\uFF65]|\uD800[\uDD00-\uDD02\uDF9F\uDFD0]|\uD801\uDD6F|\uD802[\uDC57\uDD1F\uDD3F\uDE50-\uDE58\uDE7F\uDEF0-\uDEF6\uDF39-\uDF3F\uDF99-\uDF9C]|\uD804[\uDC47-\uDC4D\uDCBB\uDCBC\uDCBE-\uDCC1\uDD40-\uDD43\uDD74\uDD75\uDDC5-\uDDC8\uDDCD\uDE38-\uDE3D]|\uD805[\uDCC6\uDDC1-\uDDC9\uDE41-\uDE43]|\uD809[\uDC70-\uDC74]|\uD81A[\uDE6E\uDE6F\uDEF5\uDF37-\uDF3B\uDF44]|\uD82F\uDC9F/
      # was unable to get abouve to work TODO
      UNICODE_PUNCT_RE = /[!-#%-\*,-\/:;\?@\[-\]_\{\}]/

      # Currently without astral characters support.
      #------------------------------------------------------------------------------
      def isPunctChar(char)
        return UNICODE_PUNCT_RE =~ char
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