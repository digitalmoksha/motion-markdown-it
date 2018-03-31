# For each opening emphasis-like marker find a matching closing one
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class BalancePairs

      #------------------------------------------------------------------------------
      def self.link_pairs(state)
        delimiters = state.delimiters
        max = state.delimiters.length

        0.upto(max - 1) do |i|
          lastDelim = delimiters[i]

          next if !lastDelim[:close]

          j = i - lastDelim[:jump] - 1

          while j >= 0
            currDelim = delimiters[j]

            if currDelim[:open] &&
               currDelim[:marker] == lastDelim[:marker] &&
               currDelim[:end] < 0 &&
               currDelim[:level] == lastDelim[:level]

              lastDelim[:jump] = i - j
              lastDelim[:open] = false
              currDelim[:end]  = i
              currDelim[:jump] = 0
              break
            end

            j -= currDelim[:jump] + 1
          end
        end
      end
    end
  end
end