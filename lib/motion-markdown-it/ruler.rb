# * class Ruler
# *
# * Helper class, used by [[MarkdownIt#core]], [[MarkdownIt#block]] and
# * [[MarkdownIt#inline]] to manage sequences of functions (rules):
# *
# * - keep rules in defined order
# * - assign the name to each rule
# * - enable/disable rules
# * - add/replace rules
# * - allow assign rules to additional named chains (in the same)
# * - cacheing lists of active rules
# *
# * You will not need use this class directly until write plugins. For simple
# * rules control use [[MarkdownIt.disable]], [[MarkdownIt.enable]] and
# * [[MarkdownIt.use]].
#------------------------------------------------------------------------------

module MarkdownIt
  class Ruler 

    def initialize
      # // List of added rules. Each element is:
      # //
      # // {
      # //   name: XXX,
      # //   enabled: Boolean,
      # //   fn: Function(),
      # //   alt: [ name2, name3 ]
      # // }
      @__rules__ = []

      # // Cached rule chains.
      # //
      # // First level - chain name, '' for default.
      # // Second level - diginal anchor for fast filtering by charcodes.
      @__cache__ = nil
    end

    #------------------------------------------------------------------------------
    # // Helper methods, should not be used directly


    # // Find rule index by name
    #------------------------------------------------------------------------------
    def __find__(name)
      @__rules__.each_with_index do |rule, index|
        return index if (rule[:name] == name)
      end
      return -1
    end


    # // Build rules lookup cache
    #------------------------------------------------------------------------------
    def __compile__
      chains = [ '' ]

      # // collect unique names
      @__rules__.each do |rule|
        next if !rule[:enabled]

        rule[:alt].each do |altName|
          if !chains.include?(altName)
            chains.push(altName)
          end
        end
      end

      @__cache__ = {}

      chains.each do |chain|
        @__cache__[chain] = []
        @__rules__.each do |rule|
          next if !rule[:enabled]
          next if (chain && !rule[:alt].include?(chain))

          @__cache__[chain].push(rule[:fn])
        end
      end
    end


    # * Ruler.at(name, fn [, options])
    # * - name (String): rule name to replace.
    # * - fn (Function): new rule function.
    # * - options (Object): new rule options (not mandatory).
    # *
    # * Replace rule by name with new function & options. Throws error if name not
    # * found.
    # *
    # * ##### Options:
    # *
    # * - __alt__ - array with names of "alternate" chains.
    # *
    # * ##### Example
    # *
    # * Replace existing typorgapher replacement rule with new one:
    # *
    # * ```javascript
    # * var md = require('markdown-it')();
    # *
    # * md.core.ruler.at('replacements', function replace(state) {
    # *   //...
    # * });
    # * ```
    #------------------------------------------------------------------------------
    def at(name, fn, opt = {})
      index = __find__(name)

      raise(StandardError, "Parser rule not found: #{name}") if index == -1
      
      @__rules__[index][:fn] = fn
      @__rules__[index][:alt] = opt[:alt] || ['']
      @__cache__ = nil
    end


    # * Ruler.before(beforeName, ruleName, fn [, options])
    # * - beforeName (String): new rule will be added before this one.
    # * - ruleName (String): name of added rule.
    # * - fn (Function): rule function.
    # * - options (Object): rule options (not mandatory).
    # *
    # * Add new rule to chain before one with given name. See also
    # * [[Ruler.after]], [[Ruler.push]].
    # *
    # * ##### Options:
    # *
    # * - __alt__ - array with names of "alternate" chains.
    # *
    # * ##### Example
    # *
    # * ```javascript
    # * var md = require('markdown-it')();
    # *
    # * md.block.ruler.before('paragraph', 'my_rule', function replace(state) {
    # *   //...
    # * });
    # * ```
    #------------------------------------------------------------------------------
    def before(beforeName, ruleName, fn, opt = {})
      index = __find__(beforeName)

      raise(StandardError, "Parser rule not found: #{beforeName}") if index == -1

      @__rules__.insert(index, {
        name: ruleName,
        enabled: true,
        fn: fn,
        alt: (opt[:alt] || [''])
      })

      @__cache__ = nil
    end


    # * Ruler.after(afterName, ruleName, fn [, options])
    # * - afterName (String): new rule will be added after this one.
    # * - ruleName (String): name of added rule.
    # * - fn (Function): rule function.
    # * - options (Object): rule options (not mandatory).
    # *
    # * Add new rule to chain after one with given name. See also
    # * [[Ruler.before]], [[Ruler.push]].
    # *
    # * ##### Options:
    # *
    # * - __alt__ - array with names of "alternate" chains.
    # *
    # * ##### Example
    # *
    # * ```javascript
    # * var md = require('markdown-it')();
    # *
    # * md.inline.ruler.after('text', 'my_rule', function replace(state) {
    # *   //...
    # * });
    # * ```
    #------------------------------------------------------------------------------
    def after(afterName, ruleName, fn, opt = {})
      index = __find__(afterName)

      raise(StandardError, "Parser rule not found: #{afterName}") if index == -1

      @__rules__.insert(index + 1, {
        name: ruleName,
        enabled: true,
        fn: fn,
        alt: (opt[:alt] || [''])
      })

      @__cache__ = nil
    end

    # * Ruler.push(ruleName, fn [, options])
    # * - ruleName (String): name of added rule.
    # * - fn (Function): rule function.
    # * - options (Object): rule options (not mandatory).
    # *
    # * Push new rule to the end of chain. See also
    # * [[Ruler.before]], [[Ruler.after]].
    # *
    # * ##### Options:
    # *
    # * - __alt__ - array with names of "alternate" chains.
    # *
    # * ##### Example
    # *
    # * ```javascript
    # * var md = require('markdown-it')();
    # *
    # * md.core.ruler.push('my_rule', function replace(state) {
    # *   //...
    # * });
    # * ```
    #------------------------------------------------------------------------------
    def push(ruleName, fn, opt = {})
      @__rules__.push({
        name: ruleName,
        enabled: true,
        fn: fn,
        alt: (opt[:alt] ? [''] + opt[:alt] : [''])
      })
      @__cache__ = nil
    end


    # * Ruler.enable(list [, ignoreInvalid]) -> Array
    # * - list (String|Array): list of rule names to enable.
    # * - ignoreInvalid (Boolean): set `true` to ignore errors when rule not found.
    # *
    # * Enable rules with given names. If any rule name not found - throw Error.
    # * Errors can be disabled by second param.
    # *
    # * Returns list of found rule names (if no exception happened).
    # *
    # * See also [[Ruler.disable]], [[Ruler.enableOnly]].
    #------------------------------------------------------------------------------
    def enable(list, ignoreInvalid = false)
      list = [ list ] if !list.is_a?(Array)
      result = []

      # // Search by name and enable
      list.each do |name|
        idx = __find__(name)

        if idx < 0
          next if ignoreInvalid
          raise(StandardError, "Rules manager: invalid rule name #{name}")
        end
        @__rules__[idx][:enabled] = true
        result.push(name)
      end

      @__cache__ = nil
      return result
    end


    # * Ruler.enableOnly(list [, ignoreInvalid])
    # * - list (String|Array): list of rule names to enable (whitelist).
    # * - ignoreInvalid (Boolean): set `true` to ignore errors when rule not found.
    # *
    # * Enable rules with given names, and disable everything else. If any rule name
    # * not found - throw Error. Errors can be disabled by second param.
    # *
    # * See also [[Ruler.disable]], [[Ruler.enable]].
    #------------------------------------------------------------------------------
    def enableOnly(list, ignoreInvalid = false)
      list = [ list ] if !list.is_a?(Array)

      @__rules__.each { |rule| rule[:enabled] = false }

      enable(list, ignoreInvalid)
    end


    # * Ruler.disable(list [, ignoreInvalid]) -> Array
    # * - list (String|Array): list of rule names to disable.
    # * - ignoreInvalid (Boolean): set `true` to ignore errors when rule not found.
    # *
    # * Disable rules with given names. If any rule name not found - throw Error.
    # * Errors can be disabled by second param.
    # *
    # * Returns list of found rule names (if no exception happened).
    # *
    # * See also [[Ruler.enable]], [[Ruler.enableOnly]].
    #------------------------------------------------------------------------------
    def disable(list, ignoreInvalid = false)
      list = [ list ] if !list.is_a?(Array)
      result = []

      # // Search by name and disable
      list.each do |name|
        idx = __find__(name)

        if idx < 0
          next if ignoreInvalid
          raise(StandardError, "Rules manager: invalid rule name #{name}")
        end
        @__rules__[idx][:enabled] = false
        result.push(name)
      end

      @__cache__ = nil
      return result
    end


    # * Ruler.getRules(chainName) -> Array
    # *
    # * Return array of active functions (rules) for given chain name. It analyzes
    # * rules configuration, compiles caches if not exists and returns result.
    # *
    # * Default chain name is `''` (empty string). It can't be skipped. That's
    # * done intentionally, to keep signature monomorphic for high speed.
    #------------------------------------------------------------------------------
    def getRules(chainName)
      if @__cache__ == nil
        __compile__
      end

      # // Chain can be empty, if rules disabled. But we still have to return Array.
      return @__cache__[chainName] || []
    end
  end
end
