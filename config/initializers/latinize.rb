# encoding: utf-8
# from TI Georgia: https://github.com/tigeorgia/georgian-language-toolkit
# Add additional Georgian language functionality to String class

####################################
#### Additional instance methods ###
####################################
# def latinize(map = LANG_MAP_TO_GEO)
# def georgianize(map = LANG_MAP_TO_ENG)
# def get_language
# def is_georgian?
# def is_latin?
# def georgian_morph(type = 'basic') - THIS NEEDS DEVELOPMENT

class String
  # Set whether you want output in the terminal (for development)
  Output = false

  # Converts Georgian script to latin;
  # doing this for all strings because the morphology in sphinx works well in English
  def latinize(map = LANG_MAP_TO_GEO)
    new_string = String.new(self)
    map.each do |latin, georgian|
      georgian.each do |ge|
        new_string.gsub!(ge,latin)
      end
    end
    if Output
      puts "------------------------------------------------------------------------------"
      puts "String::latinize"
      puts "String '#{self}' has been latinized to #{new_string}"
      puts "------------------------------------------------------------------------------"
    end
    new_string
  end

  # Converts Latin script to Georgian - uses keyboard syntax, so T => თ and t => ტ
  def georgianize(map = LANG_MAP_TO_ENG)
    new_string = String.new(self)
    map.each do |latin, georgian|
      new_string.gsub!(latin,georgian)
    end
    if Output
      puts "------------------------------------------------------------------------------"
      puts "String::georgianize"
      puts "String '#{self}' has been georgianized to #{new_string}"
      puts "------------------------------------------------------------------------------"
    end
    new_string
  end


  def latinize_to_code(map = LANG_MAP_TO_GEO3)
    new_string = String.new(self)
    map.each do |latin, georgian|
      new_string.gsub!(georgian, latin)
    end
    if Output
      puts "------------------------------------------------------------------------------"
      puts "String::latinize_with_code"
      puts "String '#{self}' has been latinized to #{new_string}"
      puts "------------------------------------------------------------------------------"
    end
    new_string
  end

  def georgianize_from_code(map = LANG_MAP_TO_GEO4)
    new_string = String.new(self)
    map.each do |latin, georgian|
      new_string.gsub!(latin, georgian)
    end
    if Output
      puts "------------------------------------------------------------------------------"
      puts "String::georgianize_from_code"
      puts "String '#{self}' has been georgianized to #{new_string}"
      puts "------------------------------------------------------------------------------"
    end
    new_string
  end


  def latinize_georgianize()
    new_string = String.new(self)
    LANG_MAP1.each do |latin, georgian|
      georgian.each do |ge|
        new_string.gsub!(ge,latin)
      end
    end
    new_string2 = String.new(new_string)
    LANG_MAP2.each do |latin, georgian|
      new_string2.gsub!(latin, georgian)
    end
    if Output
      puts "------------------------------------------------------------------------------"
      puts "String::georgianize"
      puts "String '#{self}' has been georgianized to #{new_string}"
      puts "------------------------------------------------------------------------------"
    end
    new_string2
  end


  # Returns the language of the string, either Georgian or English
  def get_language
    ka_letters = self.count("ა-ჰ")
    en_letters = self.count("a-zA-Z")
    if Output
      puts "------------------------------------------------------------------------------"
      puts "String::get_language"
      puts "String '#{self}' has #{en_letters} english and #{ka_letters} georgian letters"
      puts "------------------------------------------------------------------------------"
    end
    return en_letters >= ka_letters ? 'en' : 'ka'
  end

  # Returns true if the string is predominantly in Georgian characters
  def is_georgian?
    self.get_language == 'ka' ? true : false
  end

  # Returns true if the string is predominantly in Latin characters
  def is_latin?
    self.get_language == 'en' ? true : false
  end

  # Returns a string that has been simplified by Georgian language morphology rules
  #  if set to 'basic' (default) will convert common characters to their common format
  #  if set to 'extended' will also convert common word morphs to their unmorphed form
  #  ex. 'ceretlis qucha' in basic mode will output 'tseretlis qucha'
  #                       in extended mode will output 'tsereteli qucha'
  def georgian_morph(type = 'basic')
    new_string_terms = String.new(self).split(' ')
    if type == 'basic' or type == 'extended'
      new_string_terms.each do |term|
        for i in 0..term.length-1
          if term[i] == 'c' && term[i+1] != nil && term[i+1] != 'h'
            term[i] = 'ts'
          end
          if term[i] == 'f'
            term[i] = 'p'
          end
          if term[i] == 'p' && term[i+1] != nil && term[i+1] == 'h'
            term[i..i+1] = 'p'
          end
          if term[i] == 'x'
            term[i] = 'kh'
          end
        end
      end
    end
    if type == 'extended'
      new_string_terms.each do |term|
        term.gsub!('eblis','ebeli') if term.include?('eblis')
        term.gsub!('etlis','eteli') if term.include?('etlis')
        term.gsub!('dzis','dze') if term.include?('dzis')
        term[term.length-1] = '' if term[term.length-1] == 's' # remove any 's' from the end of a term
      end
    end
    if Output
      puts "------------------------------------------------------------------------------"
      puts "String::georgian_morph"
      puts "String '#{self}' has been morphed to #{new_string_terms.join(' ')}"
      puts "------------------------------------------------------------------------------"
    end
    return new_string_terms.join(' ')
  end


  # CONSTANTS #
  LANG_MAP_TO_GEO = { 'a'   => ['ა'],
                      'b'   => ['ბ'],
                      'g'   => ['გ'],
                      'd'   => ['დ'],
                      'e'   => ['ე'],
                      'v'   => ['ვ'],
                      'z'   => ['ზ'],
                      'i'   => ['ი'],
                      'l'   => ['ლ'],
                      'm'   => ['მ'],
                      'n'   => ['ნ'],
                      'o'   => ['ო'],
                      'zh'  => ['ჟ'],
                      'r'   => ['რ'],
                      's'   => ['ს'],
                      't'   => ['ტ','თ'],
                      'u'   => ['უ'],
                      'p'   => ['პ','ფ'],
                      'k'   => ['კ','ყ'],
                      'gh'  => ['ღ'],
                      'q'   => ['ქ'],
                      'sh'  => ['შ'],
                      'dz'  => ['ძ'],
                      'ts'  => ['ც','წ'],
                      'ch'  => ['ჩ','ჭ'],
                      'kh'  => ['ხ'],
                      'j'   => ['ჯ'],
                      'h'   => ['ჰ']  }

  LANG_MAP_TO_ENG = { 'tch' => 'ჭ',
                      'Tch' => 'ჭ',
                      'th'  => 'ტ',
                      'Th'  => 'ტ',
                      'gh'  => 'ღ',
                      'Gh'  => 'ღ',
                      'zh'  => 'ჟ',
                      'Zh'  => 'ჟ',
                      'sh'  => 'შ',
                      'Sh'  => 'შ',
                      'dz'  => 'ძ',
                      'Dz'  => 'ძ',
                      'ts'  => 'ც',
                      'Ts'  => 'ც',
                      'tz'  => 'წ',
                      'Tz'  => 'წ',
                      'ch'  => 'ჩ',
                      'Ch'  => 'ჩ',
                      'kh'  => 'ხ',
                      'Kh'  => 'ხ',
                      'W'   => 'ჭ',
                      't'   => 'ტ',
                      'T'   => 'თ',
                      'R'   => 'ღ',
                      'J'   => 'ჟ',
                      'S'   => 'შ',
                      'Z'   => 'ძ',
                      'c'   => 'ც',
                      'w'   => 'წ',
                      'C'   => 'ჩ',
                      'x'   => 'ხ',
                      'y'   => 'ყ',
                      'a'   => 'ა',
                      'b'   => 'ბ',
                      'g'   => 'გ',
                      'd'   => 'დ',
                      'e'   => 'ე',
                      'v'   => 'ვ',
                      'z'   => 'ზ',
                      'i'   => 'ი',
                      'l'   => 'ლ',
                      'm'   => 'მ',
                      'n'   => 'ნ',
                      'o'   => 'ო',
                      'r'   => 'რ',
                      's'   => 'ს',
                      'u'   => 'უ',
                      'p'   => 'პ',
                      'f'   => 'ფ',
                      'k'   => 'კ',
                      'q'   => 'ქ',
                      'j'   => 'ჯ',
                      'h'   => 'ჰ' }


  LANG_MAP1 = { 
                      '1_a'   => ['ა'],
                      '1_b'   => ['ბ'],
                      '1_g'   => ['გ'],
                      '1_d'   => ['დ'],
                      '1_e'   => ['ე'],
                      '1_v'   => ['ვ'],
                      '1_z'   => ['ზ'],
                      '1_i'   => ['ი'],
                      '1_l'   => ['ლ'],
                      '1_m'   => ['მ'],
                      '1_n'   => ['ნ'],
                      '1_o'   => ['ო'],
                      '1_zh'  => ['ჟ'],
                      '1_r'   => ['რ'],
                      '1_s'   => ['ს'],
                      '1_t'   => ['ტ'],
                      '1_T'   => ['თ'],
                      '1_u'   => ['უ'],
                      '1_p'   => ['პ'],
                      '1_f'   => ['ფ'],
                      '1_k'   => ['კ'],
                      '1_y'   => ['ყ'],
                      '1_gh'  => ['ღ'],
                      '1_q'   => ['ქ'],
                      '1_sh'  => ['შ'],
                      '1_dz'  => ['ძ'],
                      '1_c'  => ['ც'],
                      '1_w'  => ['წ'],
                      '1_C'  => ['ჩ'],
                      '1_W'  => ['ჭ'],
                      '1_kh'  => ['ხ'],
                      '1_j'   => ['ჯ'],
                      '1_h'   => ['ჰ']  }

  LANG_MAP2 = { 
                      '1_kh'  => 'ხ',
                      '1_zh'  => 'ჟ',
                      '1_gh'  => 'ღ',
                      '1_sh'  => 'შ',
                      '1_dz'  => 'ძ',
                      '1_a'   => 'ა',
                      '1_b'   => 'ბ',
                      '1_g'   => 'გ',
                      '1_d'   => 'დ',
                      '1_e'   => 'ე',
                      '1_v'   => 'ვ',
                      '1_z'   => 'ზ',
                      '1_i'   => 'ი',
                      '1_l'   => 'ლ',
                      '1_m'   => 'მ',
                      '1_n'   => 'ნ',
                      '1_o'   => 'ო',
                      '1_r'   => 'რ',
                      '1_s'   => 'ს',
                      '1_t'   => 'ტ',
                      '1_T'   => 'თ',
                      '1_u'   => 'უ',
                      '1_p'   => 'პ',
                      '1_f'   => 'ფ',
                      '1_k'   => 'კ',
                      '1_y'   => 'ყ',
                      '1_q'   => 'ქ',
                      '1_c'  => 'ც',
                      '1_w'  => 'წ',
                      '1_C'  => 'ჩ',
                      '1_W'  => 'ჭ',
                      '1_j'   => 'ჯ',
                      '1_h'   => 'ჰ'  }





  LANG_MAP_TO_GEO_CODE = { 'aa'   => ['ა'],
                       'bb'   => ['ბ'],
                       'gg'   => ['გ'],
                       'dd'   => ['დ'],
                       'ee'   => ['ე'],
                       'vv'   => ['ვ'],
                       'zz'   => ['ზ'],
                       'ii'   => ['ი'],
                       'll'   => ['ლ'],
                       'mm'   => ['მ'],
                       'nn'   => ['ნ'],
                       'oo'   => ['ო'],
                       'zhzh'  => ['ჟ'],
                       'rr'   => ['რ'],
                       'ss'   => ['ს'],
                       'tt'   => ['ტ'],
                       'TT'   => ['თ'],
                       'uu'   => ['უ'],
                       'pp'   => ['პ'],
                       'ff'   => ['ფ'],
                       'kk'   => ['კ'],
                       'yy'   => ['ყ'],
                       'ghgh'  => ['ღ'],
                       'qq'   => ['ქ'],
                       'shsh'  => ['შ'],
                       'dzdz'  => ['ძ'],
                       'cc'  => ['ც'],
                       'ww'  => ['წ'],
                       'CC'  => ['ჩ'],
                       'WW'  => ['ჭ'],
                       'khkh'  => ['ხ'],
                       'jj'   => ['ჯ'],
                       'hh'   => ['ჰ']  }

  LANG_MAP_TO_ENG_CODE = { 'aa'   => 'ა',
                       'bb'   => 'ბ',
                       'gg'   => 'გ',
                       'dd'   => 'დ',
                       'ee'   => 'ე',
                       'vv'   => 'ვ',
                       'zz'   => 'ზ',
                       'ii'   => 'ი',
                       'll'   => 'ლ',
                       'mm'   => 'მ',
                       'nn'   => 'ნ',
                       'oo'   => 'ო',
                       'zhzh'  => 'ჟ',
                       'rr'   => 'რ',
                       'ss'   => 'ს',
                       'tt'   => 'ტ',
                       'TT'   => 'თ',
                       'uu'   => 'უ',
                       'pp'   => 'პ',
                       'ff'   => 'ფ',
                       'kk'   => 'კ',
                       'yy'   => 'ყ',
                       'ghgh'  => 'ღ',
                       'qq'   => 'ქ',
                       'shsh'  => 'შ',
                       'dzdz'  => 'ძ',
                       'cc'  => 'ც',
                       'ww'  => 'წ',
                       'CC'  => 'ჩ',
                       'WW'  => 'ჭ',
                       'khkh'  => 'ხ',
                       'jj'   => 'ჯ',
                       'hh'   => 'ჰ'  }

end
