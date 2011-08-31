#encoding: utf-8

LETTERS = ("a".."z").to_a.join

#inspired by http://norvig.com/spell-correct.html
#and http://lojic.com/blog/2008/09/04/how-to-write-a-spelling-corrector-in-ruby/

module SpellingCorrector
  class Engine
    
    def words text
      text.downcase.scan(/[a-z]+/)
    end

    def train features
      model = Hash.new(1)
      features.each {|f| model[f] += 1 }
      return model
    end
    
    def initialize(corpus_name)
      corpus_filename =  File.expand_path("../../corpus/#{corpus_name}.txt", __FILE__)
      #puts "Load corpus: #{corpus_filename}"
      @nwords = train(words(File.new(corpus_filename).read))
    end
    
    def edits1 word
      n = word.length
      deletion = (0...n).collect {|i| word[0...i]+word[i+1..-1] }
      transposition = (0...n-1).collect {|i| word[0...i]+word[i+1,1]+word[i,1]+word[i+2..-1] }
      #alteration = (0…n).collect { |i| (0…26).collect { |l| word[0...i] + LETTERS[l].chr+word[i+1..-1] } }.flatten
      alteration = []
      n.times {|i| LETTERS.each_byte {|l| alteration << word[0...i]+l.chr+word[i+1..-1] } }
      insertion = []
      (n+1).times {|i| LETTERS.each_byte {|l| insertion << word[0...i]+l.chr+word[i..-1] } }
      result = deletion + transposition + alteration + insertion
      result.empty? ? nil : result
    end

    def known_edits2 word
      result = []
      edits1(word).each {|e1| edits1(e1).each {|e2| result << e2 if @nwords.has_key?(e2) }}
      #result.empty? ? nil : result
      #!result.empty? && result
      result.any? && result
    end

    def known words
      result = words.find_all {|w| @nwords.has_key?(w) }
      #result.empty? ? nil : result
      result.any? && result
    end

    def correct word
      (known([word]) or known(edits1(word)) or known_edits2(word) or
        [word]).max {|a,b| @nwords[a] <=> @nwords[b] }
    end
    
  end
end
