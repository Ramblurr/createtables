#!/usr/bin/ruby

# createtables.rb -- Version 0.0.1
#
# This code generates tables for IDNA2008.
#
# It requires a number of files from the Unicode distribution, and
# configuration of some paths in this, the code itself.
#
# Written by Patrik Faltstrom <paf@cisco.com>
#
# Copyright (c) 2010, Cisco Systems, Inc
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list of conditions
# and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this list of conditions
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
# Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to endorse or
# promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#


require 'rubygems'
#require 'idn'

def stringToArray(s)
  if(s.class == Array)
    return(s)
  end
  a = Array.new
  if(s.class == Fixnum)
    a.push(s)
    return(a)
  end
  if(s.class == String)
    s.strip!
    s.gsub!(/u\+/i,'')
    s.split(/\s+/).each do |c|
      a.push(c.to_i(16))
    end
    if(a.length == 0)
      return nil
    end
    return(a)
  end
  return nil
end

def toUnicode(cp)
  return sprintf("U+%04X",cp)
end
  
def unicodify(s)
  s.gsub!(/[U]?[\+]?([A-F0-9]+)/,'U+\1')
end  

def arrayToUnicode(a)
  s = String.new
  a.each do |cp|
    s = s + " " + toUnicode(cp)
  end
  s.strip!
  return s
end

class UnicodeBlock
  protected

  def initialize(blockName)
    @myName = blockName.strip
    @codepoints = Hash.new
  end
  
  public

  def to_s
    return @myName
  end

  def addCodePoint(codePoint)
    unless(@codepoints.has_key?(codePoint.to_i))
      @codepoints[codePoint.to_i] = codePoint
      codePoint.setBlock(self)
    end
  end

end

class UnicodeScript
  protected

  def initialize(scriptName)
    @myName = scriptName.strip
    @codepoints = Hash.new
  end
  
  public

  def to_s
    return @myName
  end

  def addCodePoint(codePoint)
    unless(@codepoints.has_key?(codePoint.to_i))
      @codepoints[codePoint.to_i] = 0
      codePoint.setScript(self)
    end
  end

  def codepoints
    return @codepoints.keys
  end
end

class UnicodeProperty
  protected

  def initialize(propertyName)
    @myName = propertyName.strip
    @codepoints = Hash.new
  end
  
  public

  def to_s
    return @myName
  end

  def addCodePoint(codePoint)
    unless(@codepoints.has_key?(codePoint.to_i))
      @codepoints[codePoint.to_i] = codePoint
      codePoint.setProperty(self)
    end
  end

end

class UnicodeCharacter
  protected
  
  def initialize(charCode)
    @charCode = charCode             # Note that charCode is an Integer
    @myName = ""
    @myGeneralCategory = ""
    @myCanonicalCombiningClass = 0
    @myBidiClass = ""
    @myDecompositionType = ""
    @myDecompositionMapping = nil
    @myCaseFolding = nil
    @myBlock = nil
    @myScript = nil
    @myHangulSyllableType = nil
    @myProperties = Hash.new
  end

  public

  def theChar
    return [@charCode].pack("U")
  end
  
  def theIdnaRuleA
    return("generalCategory(cp) is in {Ll, Lu, Lo, Nd, Lm, Mn, Mc}")
  end
  
  def idnaRuleA?(u)
    # generalCategory(cp) is in {Ll, Lu, Lo, Nd, Lm, Mn, Mc}
    return (["Ll", "Lu", "Lo", "Nd", "Lm", "Mn", "Mc"].include?(generalCategory))
  end

  def idnaRuleA_to_s(u)
    if(idnaRuleA?(u))
      return "A"
    else
      return ""
    end
  end

  def theIdnaRuleB
    return("NFKC(casefold(NFKC(cp))) != cp")
  end
  
  def idnaRuleB?(u)
    # NFKC(casefold(NFKC(cp))) != cp
    return(u.nfkc(u.casefold(u.nfkc([to_i]))) != [to_i])
  end

  def idnaRuleB_to_s(u)
    if(idnaRuleB?(u))
      return "B"
    else
      return ""
    end
  end
  
  def theIdnaRuleC
    return("property(cp) is in {Default_Ignorable_Code_Point, White_Space, Noncharacter_Code_Point}")
  end
  
  def idnaRuleC?(u)
    return(hasProperty?("Default_Ignorable_Code_Point") || hasProperty?("White_Space") || hasProperty?("Noncharacter_Code_Point"))
  end
  
  def idnaRuleC_to_s(u)
    if(idnaRuleC?(u))
      return "C"
    else
      return ""
    end
  end

  def theIdnaRuleD
    return("block(cp) in {Combining_Diacritical_Marks_for_Symbols, Musical_Symbols, Ancient_Greek_Musical_Notation,}")
  end
  
  def idnaRuleD?(u)
    # block(cp) in {Combining_Diacritical_Marks_for_Symbols,Musical_Symbols, Ancient_Greek_Musical_Notation}
    return(["Combining Diacritical Marks for Symbols", "Musical Symbols", "Ancient Greek Musical Notation"].include?(block.to_s))
  end

  def idnaRuleD_to_s(u)
    if(idnaRuleD?(u))
      return "D"
    else
      return ""
    end
  end

  def theIdnaRuleE
    return("cp is in [-a-z0-9]")
  end

  def idnaRuleE?(u)
    # cp is in [-A-Z0-9]
    return(@charCode == 0x2D || (@charCode >= 0x30 && @charCode <= 0x39) || (@charCode >= 0x61 && @charCode <= 0x7A))
  end

  def idnaRuleE_to_s(u)
    if(idnaRuleE?(u))
      return "E"
    else
      return ""
    end
  end

  def theIdnaRuleF
    return("cp is in {0x00B7, 0x00DF, 0x0375, 0x03C2, 0x05F3, 0x05F4, 0x0660, 0x0661, 0x0662, 0x0663, 0x0664, 0x0665, 0x0666, 0x0667, 0x0668, 0x0669, 0x06F0, 0x06F1, 0x06F2, 0x06F3, 0x06F4, 0x06F5, 0x06F6, 0x06F7, 0x06F8, 0x06F9, 0x06FD, 0x06FE, 0x0F0B, 0x3007, 0x302E, 0x303F, 0x303B, 0x30FB}")
  end

  def idnaRuleF?(u)
    ans = idnaRuleF_value(u)
    return(ans.length > 0)
  end

  def idnaRuleF_value(u)
    return("PVALID") if(@charCode == 0x00DF)
    return("PVALID") if(@charCode == 0x03C2)
    return("PVALID") if(@charCode == 0x06FD)
    return("PVALID") if(@charCode == 0x06FE)
    return("PVALID") if(@charCode == 0x0F0B)
    return("PVALID") if(@charCode == 0x3007)

    return("CONTEXTO") if(@charCode == 0x00B7)
    return("CONTEXTO") if(@charCode == 0x0375)
    return("CONTEXTO") if(@charCode == 0x05F3)
    return("CONTEXTO") if(@charCode == 0x05F4)
    return("CONTEXTO") if(@charCode == 0x30FB)

    return("CONTEXTO") if(@charCode == 0x0660)
    return("CONTEXTO") if(@charCode == 0x0661)
    return("CONTEXTO") if(@charCode == 0x0662)
    return("CONTEXTO") if(@charCode == 0x0663)
    return("CONTEXTO") if(@charCode == 0x0664)
    return("CONTEXTO") if(@charCode == 0x0665)
    return("CONTEXTO") if(@charCode == 0x0666)
    return("CONTEXTO") if(@charCode == 0x0667)
    return("CONTEXTO") if(@charCode == 0x0668)
    return("CONTEXTO") if(@charCode == 0x0669)
    return("CONTEXTO") if(@charCode == 0x06F0)
    return("CONTEXTO") if(@charCode == 0x06F1)
    return("CONTEXTO") if(@charCode == 0x06F2)
    return("CONTEXTO") if(@charCode == 0x06F3)
    return("CONTEXTO") if(@charCode == 0x06F4)
    return("CONTEXTO") if(@charCode == 0x06F5)
    return("CONTEXTO") if(@charCode == 0x06F6)
    return("CONTEXTO") if(@charCode == 0x06F7)
    return("CONTEXTO") if(@charCode == 0x06F8)
    return("CONTEXTO") if(@charCode == 0x06F9)

    return("DISALLOWED") if(@charCode == 0x0640)
    return("DISALLOWED") if(@charCode == 0x07FA)
    return("DISALLOWED") if(@charCode == 0x302E)
    return("DISALLOWED") if(@charCode == 0x302F)
    return("DISALLOWED") if(@charCode == 0x3031)
    return("DISALLOWED") if(@charCode == 0x3032)
    return("DISALLOWED") if(@charCode == 0x3033)
    return("DISALLOWED") if(@charCode == 0x3034)
    return("DISALLOWED") if(@charCode == 0x3035)
    return("DISALLOWED") if(@charCode == 0x303B)

    return("")
  end

  def idnaRuleF_to_s(u)
    if(idnaRuleF?(u))
      return "F"
    else
      return ""
    end
  end

  def theIdnaRuleG
    return("cp is in {}")
  end
  
  def idnaRuleG?(u)
    # cp is in {}
    return (false)
  end

  def idnaRuleG_value(u)
    return("")
  end

  def idnaRuleG_to_s(u)
    if(idnaRuleG?(u))
      return "G"
    else
      return ""
    end
  end

  def theIdnaRuleH
    return("property(cp) is in {Join_Control}")
  end
  
  def idnaRuleH?(u)
    return (hasProperty?("Join_Control"))
  end

  def idnaRuleH_to_s(u)
    if(idnaRuleH?(u))
      return "H"
    else
      return ""
    end
  end

  def theIdnaRuleJ
    return("cp is Unassigned")
  end

  def idnaRuleJ?(u)
    # cp is unassigned
    return(generalCategory == "Cn" && !(hasProperty?("Noncharacter_Code_Point")))
  end

  def idnaRuleJ_to_s(u)
    if(idnaRuleJ?(u))
      return "J"
    else
      return ""
    end
  end

  def theIdnaRuleI
    return("HangulsSyllableType(cp) in {L,V,T}")
  end

  def idnaRuleI?(u)
    return(@myHangulSyllableType == "L" || @myHangulSyllableType == "V" || @myHangulSyllableType == "T")
  end

  def idnaRuleI_to_s(u)
    if(idnaRuleI?(u))
      return "I"
    else
      return ""
    end
  end
        
  def uLabel_to_s(u)
    if(idnaRuleF?(u))
      return idnaRuleF_value(u)
    end

    if(idnaRuleG?(u))
      return idnaRuleG_value(u)
    end

    if(idnaRuleJ?(u))
      return "UNASSIGNED"
    end

    if(idnaRuleE?(u))
      return "PVALID"
    end

    if(idnaRuleH?(u))
      return "CONTEXTJ"
    end

    if(idnaRuleB?(u))
      return "DISALLOWED"
    end

    if(idnaRuleI?(u))
      return "DISALLOWED"
    end

    if(idnaRuleC?(u))
      return "DISALLOWED"
    end

    if(idnaRuleD?(u))
      return "DISALLOWED"
    end

    if(idnaRuleA?(u))
      return "PVALID"
    end

    return("DISALLOWED")

  end

  def inNewIDNA(u)
    a = uLabel_to_s(u)
    if(a == "PVALID")
      return("Y")
    end
    if(a == "UNASSIGNED")
      return("I")
    end
    if(a == "CONTEXTJ")
      return("J")
    end
    if(a == "CONTEXTO")
      return("O")
    end
    if(a == "DISALLOWED")
      b = u.casefold([to_i])
    end
  end
  
  def inOldIDNA(u)
    begin
      a = theChar
      aa = IDN::Stringprep.nameprep(theChar)
      b = IDN::Idna.toASCII(theChar,flags=IDN::Idna::USE_STD3_ASCII_RULES)
      bb = IDN::Idna.toASCII(aa,flags=IDN::Idna::USE_STD3_ASCII_RULES)
      c = IDN::Idna.toUnicode(b,flags=IDN::Idna::USE_STD3_ASCII_RULES)
      cc = IDN::Idna.toUnicode(bb,flags=IDN::Idna::USE_STD3_ASCII_RULES)
      if(c==a)
        return "Y"
      elsif(cc==bb)  
        return "M"
      else
        return "N"
      end
    rescue
      return "I"
    end
  end

  def rules_to_s(u)
    s = sprintf("%s%s%s%s%s%s%s%s%s%s",idnaRuleA_to_s(u),idnaRuleB_to_s(u),idnaRuleC_to_s(u),idnaRuleD_to_s(u),idnaRuleE_to_s(u),idnaRuleF_to_s(u),idnaRuleG_to_s(u),idnaRuleH_to_s(u),idnaRuleI_to_s(u),idnaRuleJ_to_s(u))
  end
  
  def pretty(u)
    if(idnaRuleJ?(u))
      s = sprintf("%s:<Unassigned>::::::::::::%s",to_s,idnaRuleJ_to_s(u))
    else
      s = sprintf("%s:%s:%s:%d:%s:%s:%s:%s:%s:%s:%s:%s:%s",to_s,name,generalCategory,canonicalCombiningClass,bidiClass,decompositionType,decompositionMapping_to_s,caseFolding_to_s,hangulSyllableType,block.to_s,script.to_s,properties_to_s,rules_to_s(u))
    end
    return s
  end
  
  def to_i
    return @charCode
  end
  
  def to_s
    return toUnicode(to_i)
  end

  def setName(newName)
    @myName = newName
  end

  def name
    if(@myName.length == 0)
      if(hasProperty?("Noncharacter_Code_Point"))
        return "<noncharacter>"
      else
        return "<reserved>"
      end
    else
      return @myName
    end
  end

  def setGeneralCategory(newGeneralCategory)
    @myGeneralCategory = newGeneralCategory.strip
  end
  
  def generalCategory
    if(@myGeneralCategory.length == 0)
      return "Foobar"
    else
      return @myGeneralCategory
    end
  end

  def setHangulSyllableType(syllableType)
    @myHangulSyllableType = syllableType
  end
  
  def hangulSyllableType
    if(@myHangulSyllableType == nil)
      return ""
    else
      return @myHangulSyllableType
    end
  end
  
  def setCanonicalCombiningClass(newCanonicalCombiningClass)
    @myCanonicalCombiningClass = newCanonicalCombiningClass.to_i
  end
  
  def canonicalCombiningClass
    return @myCanonicalCombiningClass
  end

  def setBidiClass(newBidiClass)
    @myBidiClass = newBidiClass.strip
  end
  
  def bidiClass
    if(@myBidiClass.length == 0)
      if(hasProperty?("Noncharacter_Code_Point"))
        return "L"
      elsif(block == "Hebrew" || block == "Cypriot Syllabary" || block == "Kharoshthi")
        return "R"
      elsif((to_i >= 0x07C0 && to_i <= 0x08FF) || (to_i >= 0xFB1D && to_i <= 0xFB4F) || (to_i >= 0x10840 && to_i <= 0x109FF) || (to_i >= 0x10A60 && to_i <= 0x10FFF))
        return "R"
      elsif(block == "Arabic" || block == "Syriac" || block == "Arabic Supplement" || block == "Thaana" || block == "Arabic Presentation Forms-A" || block == "Arabic Presentation Forms-B")
        return "AL"
      else
        return "L"
      end
    else
      return @myBidiClass
    end
  end
  
  def setDecompositionType(newDecompositionType)
    if(newDecompositionType.index('<') != nil)
      @myDecompositionType = newDecompositionType.sub(/^.*(<.*>).*$/,'\1')
    else
      @myDecompositionType = ""
    end
  end

  def decompositionType()
    return @myDecompositionType
  end

  def setDecompositionMapping(newDecompositionMapping)
    if(newDecompositionMapping.class == String)
      newDecompositionMapping.sub!(/^<.*>\s*/,'')
    end
    @myDecompositionMapping = stringToArray(newDecompositionMapping)
  end
  
  def decompositionMapping
    if(@myDecompositionMapping == nil)
      return([to_i])
    else
      return @myDecompositionMapping
    end
  end

  def decompositionMapping_to_s
    return(arrayToUnicode(decompositionMapping))
  end

  def setCaseFolding(newCaseFolding)
    @myCaseFolding = stringToArray(newCaseFolding)
  end
  
  def caseFolding
    if(@myCaseFolding == nil)
      return([to_i])
    else
      return @myCaseFolding
    end
  end

  def caseFolding_to_s
    return(arrayToUnicode(caseFolding))
  end

  def setBlock(newBlock)
    @myBlock = newBlock
    newBlock.addCodePoint(self)
  end

  def block
    return @myBlock
  end

  def setScript(newScript)
    @myScript = newScript
    newScript.addCodePoint(self)
  end
  
  def script
    return @myScript
  end

  def setProperty(newProperty)
    unless(@myProperties.has_key?(newProperty.to_s))
      @myProperties[newProperty.to_s] = newProperty
      newProperty.addCodePoint(self)
    end
  end
  
  def properties
    return @myProperties
  end

  def hasProperty?(theProperty)
    return(@myProperties.has_key?(theProperty))
  end
  
  def properties_to_s
    return @myProperties.keys.join(" ")
  end

  def uLabelOk?
  end
end

def findFile(dir, filename)
  # Finds latest file that have a filename matching filename*.txt in current directory
  files = Dir[dir + filename + ".txt"]
  if(files.length == 0)
    files = Dir[dir + filename + "*.txt"]
  end
  if(files.length == 0)
    print("Did not find any " + filename + " in directory " + dir + "\n")
    exit(1)
  end
  return(files.sort[files.length - 1])
end

class Unicodedata
  protected

  def initialize(dir)
    @directory = dir

    print("Using " + @directory + "\n")
    @unicodedata = findFile(@directory, "UnicodeData")
    @casefolding = findFile(@directory, "CaseFolding")
    @block = findFile(@directory, "Blocks")
    @script = findFile(@directory, "Scripts")
    @proplist = findFile(@directory, "PropList")
    @derivedProplist = findFile(@directory, "DerivedCoreProperties")
    @exclusions = findFile(@directory, "CompositionExclusions")
    @derivedGeneralCategory = findFile(@directory, "DerivedGeneralCategory")
    @hangulDefinitions = findFile(@directory, "HangulSyllableType")
    @ucache = @directory + "unicode.cache"
    @codepoints = Hash.new
    @blocks = Hash.new
    @scripts = Hash.new
    @properties = Hash.new
    @normalizations = Hash.new
    @compositionexclusions = Hash.new

    # This is needed for broken syntax in UnicodeData.txt (and maybe others)
    # where the property values continues on more than one line
    @savedStart = 0 

    unless(loadFromCache)
      print("Creating cache file\n")
      parse
      dumpToCache
      print("Cache filel created")
    end

  end

  def dumpToCache
    File.open(@ucache,"w+") do |f|
      version = 1
      h = [version,@codepoints,@blocks,@scripts,@properties,@normalizations,@compositionexclusions]
      Marshal.dump(h, f)
    end
  end
  
  def loadFromCache
    unless (FileTest.readable?(@ucache))
      return(false)
    end
    print("Loading from cache\n")
    File.open(@ucache) do |f|
      h = Marshal.load(f)
      version = h[0]
      if(version != 1)
        print("Wrong version of cache\n")
        return false
      end
      @codepoints = h[1]
      @blocks = h[2]
      @scripts = h[3]
      @properties = h[4]
      @normalizations = h[5]
      @compositionexclusions = h[6]
    end
    print("Cache loaded/n")
    return true
  end

  def findBlock(theBlock)
    theBlock.strip!
    unless(@blocks.has_key?(theBlock))
      @blocks[theBlock] = UnicodeBlock.new(theBlock)
    end
    return @blocks[theBlock]
  end

  def findScript(theScript)
    theScript.strip!
    unless(@scripts.has_key?(theScript))
      @scripts[theScript] = UnicodeScript.new(theScript)
    end
    return @scripts[theScript]
  end

  def findProperty(theProperty)
    theProperty.strip!
    unless(@properties.has_key?(theProperty))
      @properties[theProperty] = UnicodeProperty.new(theProperty)
    end
    return @properties[theProperty]
  end

  def addNormalization(normalization, target)
    # The hash that is populated with this method is used for canonical composition
    # Both NFKC and NFC do canonical composition
    a = stringToArray(normalization)
    if(a == nil || a.length == 1)
      # No composition for singletons
      return
    end
    cp = codepoint(a[0])
    if(cp.canonicalCombiningClass > 0)
      # No composition if first codepoint is a non-starter
      return
    end
    if(@compositionexclusions.has_key?(target.to_i))
      # No composition if target is on exclusion list
      return
    end
    @normalizations[a] = target.to_i
  end
  
  def doParse(filename)
    print("Reading " + filename + "\n")
    File.open(filename,"r") do |aFile|
      aFile.each_line do |line|
        line.sub!(/#.*$/,"")
        line.strip!
        next if(line.length == 0)
        
        anArray = line.split(';')

        # The first slot is start..end in hex, or just start
        if(anArray[0].index('.') != nil)
          theStart = anArray[0].sub(/^([0-9A-Z]*)\.\..*$/,'\1').to_i(16)
          theEnd = anArray[0].sub(/^.*\.\.([0-9A-Z]*).*$/,'\1').to_i(16)
        else
          theStart = anArray[0].to_i(16)
          theEnd = theStart
        end

        # This is for UnicodeData.txt
        if(filename == @unicodedata)
          charCode = theStart
          if(anArray[1].index('First>') != nil)
            @savedStart = theStart
            next
          end
          if(anArray[1].index('Last>') != nil)
            # Reset theStart to the saved value, i.e. theStart on the previous line
            # theEnd is already correct
            theStart = @savedStart
            anArray[1].sub!(/,[^>]*/,'')
          end
          (theStart..theEnd).each do |charCode|
            cp = codepoint(charCode)
            cp.setName(anArray[1])
            cp.setGeneralCategory(anArray[2])
            cp.setCanonicalCombiningClass(anArray[3])
            cp.setBidiClass(anArray[4])
            cp.setDecompositionType(anArray[5])
            cp.setDecompositionMapping(anArray[5])
            if(cp.decompositionType.length == 0)
              addNormalization(anArray[5], cp)
            end
          end
        end

        # This is for CaseFolding.txt
        if(filename == @casefolding)
          # Only use F or C folding
          next if anArray[1] == "F" || anArray[1] == "C"

          charCode = theStart
          cp = codepoint(charCode)
          #print "Adding special casing for #{cp.to_s}\n"
          cp.setCaseFolding(anArray[2])
          #if charCode == 0x03C2
            #print "Setting case folding of 0x03C2 to #{anArray[2]}\n"
          #end
        end

        # This is for Blocks.txt
        if(filename == @block)
          (theStart..theEnd).each do |charCode|
            cp = codepoint(charCode)
            theBlock = findBlock(anArray[1])
            cp.setBlock(theBlock)
          end
        end

        # This is for Scripts.txt
        if(filename == @script)
          (theStart..theEnd).each do |charCode|
            cp = codepoint(charCode)
            theScript = findScript(anArray[1])
            cp.setScript(theScript)
          end
        end

        # This is for PropList.txt
        if(filename == @proplist || filename == @derivedProplist)
          (theStart..theEnd).each do |charCode|
            cp = codepoint(charCode)
            theProperty = findProperty(anArray[1])
            cp.setProperty(theProperty)
          end
        end

        # This is for CompositionExclusions.txt
        if(filename == @exclusions)
          (theStart..theEnd).each do |charCode|
            @compositionexclusions[charCode] = 1
          end         
        end

        # This is for DerivedGeneralCategory.txt
        if(filename == @derivedGeneralCategory)
	  anArray[1].gsub!(/ /,'')
	  if(anArray[1] == "Cn") # Optimize for IDNA2008
            (theStart..theEnd).each do |charCode|
              cp = codepoint(charCode)
              cp.setGeneralCategory(anArray[1])
	    end
          end         
        end

        # This is for HangulSyllableType.txt
        if(filename == @hangulDefinitions)
	  anArray[1].gsub!(/ /,'')
          (theStart..theEnd).each do |charCode|
            cp = codepoint(charCode)
            cp.setHangulSyllableType(anArray[1])
          end         
        end

      end
    end
  end

  public
  
  def block(theBlock)
    return findBlock(theBlock)
  end

  def script(theScript)
    return findScript(theScript)
  end
  
  def parse
    # It is important that the composition exclusions are parsed first, before we gather main data
    self.doParse(@hangulDefinitions)
    self.doParse(@exclusions)
    self.doParse(@unicodedata)
    self.doParse(@casefolding)
    self.doParse(@block)
    self.doParse(@script)
    self.doParse(@proplist)
    self.doParse(@derivedProplist)
    self.doParse(@derivedGeneralCategory)
  end
  
  def maindir
    return @directory
  end

  def codepoint(code)
    unless(@codepoints.has_key?(code))
      @codepoints[code] = UnicodeCharacter.new(code)
    end
    return(@codepoints[code])
  end
  
  def casefold(a)
    t = Array.new
    a.each do |c|
      cp = codepoint(c)
      t = t + cp.caseFolding
    end
    return(t)
  end

SBase = 0xAC00
LBase = 0x1100
VBase = 0x1161
TBase = 0x11A7
LCount = 19
VCount = 21
TCount = 28
NCount = VCount * TCount
SCount = LCount * NCount

  def hangulDecomposition(c)
    # Hangul decomposition of one character, where c is codepoint number
    # Return an array of codepoint numbers
    sIndex = c - SBase
    t = Array.new
    if (sIndex < 0 or sIndex >= SCount)
      t = t + [c]
    else
      l = LBase + sIndex / NCount
      v = VBase + (sIndex % NCount) / TCount
      tt = TBase + sIndex % TCount
      t = t + [l]
      t = t + [v]
      if (tt != TBase)
        t = t + [tt]
      end
    end
    return(t)
  end
  
  def nfkd(s)
    t = Array.new
    s.each do |c|
      if(c.class != Fixnum)
        c = c.to_i
      end
      if (c >= 0xAC00 and c <= 0xD7AF)
        t = t + hangulDecomposition(c)
      else
        # Do compatibility decomposition
	cp = codepoint(c)
        t = t + cp.decompositionMapping
      end
    end
    if(t.length > s.length)
      t = nfkd(t)
    end
    return reorder(t)
  end

  def nfd(s)
    t = Array.new
    s.each do |c|
      cp = codepoint(c)
      # Only do canonical decomposition (ignore decomposition that have decompositionType)
      if(cp.decompositionType.length == 0)
        t = t + cp.decompositionMapping
      else
        t = t + [cp.to_i]
      end
    end
    if(t.length > s.length)
      t = nfd(t)
    end
    return reorder(t)
  end

  def reorder(s)
    if(s.length == 1)
      return s
    end
    cpa = codepoint(s[0])
    (1..(s.length-1)).each do |i|
      cpb = codepoint(s[i])
      if(cpa.canonicalCombiningClass > cpb.canonicalCombiningClass)
        t = s[i]
        s[i] = s[i-1]
        s[i-1] = t
      end
      cpa = cpb
    end
    return s
  end

  def compose(s)
    if(s.length <= 1)
      return(s)
    end
    a = Array.new
    i = 0
    # Check Hangul
    # Check for L and V
    lIndex = s[i] - LBase
    if (s.length > 1 and 0 <= lIndex and lIndex < LCount)
      vIndex = s[i+1] - VBase
      if (0 <= vIndex and vIndex < VCount)
        newCodepointIndex = SBase + (lIndex * VCount + vIndex) * TCount
	return(compose([newCodepointIndex] + s[2..s.length]))
      end
    end
    # Check for LV and T
    sIndex = s[i] - SBase
    if (s.length > 1 and 0 <= sIndex and sIndex < SCount and (sIndex % TCount) == 0)
      tIndex = s[i+1] - TBase
      if (0 <= tIndex && tIndex <= TCount)
        newCodepointIndex = s[i] + tIndex
	return(compose([newCodepointIndex] + s[2..s.length]))
      end
    end
    # End of Hangul checks
    c = codepoint(s[i])
    if(c.canonicalCombiningClass > 0)
      return([c] + compose(s[1..s.length]))
    end
    j = 1
    while(j < s.length)
      if(@normalizations[s[0..j]] != nil)
        return(compose([@normalizations[s[0..j]]] + s[j+1..s.length]))
      else
        j += 1
      end
    end
    return(s)
  end
  
  def nfkc(s)
    t = nfkd(s)
    u = compose(t)
    return(u)
  end

  def nfc(s)
    t = nfd(s)
    u = compose(t)
    return(u)
  end
end

class Document
  def initialize(theFilename,theUnicode,cpStart,cpEnd,kind)
    @myFile = theFilename
    @myUnicode = theUnicode
    @myStart = cpStart
    @myEnd = cpEnd
    @myScripts = Hash.new
    @myGc = Hash.new
    
    (@myStart..@myEnd).each do |cp|
      cp = @myUnicode.codepoint(cp)
      if(cp.idnaRuleJ?(@myUnicode))
        next
      end
      unless @myScripts.has_key?(cp.script.to_s)
        @myScripts[cp.script.to_s] = 1
      end
    end

    (@myStart..@myEnd).each do |cp|
      cp = @myUnicode.codepoint(cp)
      unless @myGc.has_key?(cp.generalCategory)
        if(cp.generalCategory != "Cn")
          @myGc[cp.generalCategory] = 1
        end
      end
    end

    File.open(theFilename,"w") do |f|
      if(kind == "allgc")
        f.print startDocument
        cp = @myUnicode.codepoint(0x0000)
        f.print startSection
        f.print startHeader + "Codepoints by GeneralCategory" + endHeader
    
        @myGc.keys.sort.each do |s|
          f.print startSection
          f.print startHeader + q(s) + endHeader
          f.print startTable
          f.print startRow
          f.print startHColumn + "Code(s)" + endHColumn
          if(self.class == HTMLDocument)
            f.print startHColumn + "Char" + endColumn
          end
          f.print startHColumn + "U-label" + endHColumn
          f.print startHColumn + "Rules" + endHColumn
          if(self.class == HTMLDocument)
            f.print startHColumn + "GC" + endColumn
          end
          f.print startHColumn + "Name(s)" + endHColumn
          f.print endRow
          (@myStart..@myEnd).each do |c|
            cp = @myUnicode.codepoint(c)
            if(cp.generalCategory == s)
              if(cp.idnaRuleJ?(@myUnicode))
                next
              else
                row = startRow
                row += startColumn + cp.to_s + endColumn
                if(self.class == HTMLDocument)
                  row += startColumn + "&#x" + cp.to_s.sub("U+","") + ";" + endColumn
                end
                row += startColumn + cp.uLabel_to_s(@myUnicode) + endColumn
                row += startColumn + cp.rules_to_s(@myUnicode) + endColumn
                row += startColumn + cp.generalCategory + endColumn          
                row += startColumn + q(cp.name) + endColumn
                f.print row
                f.print endRow + "\n"
                intervalStart = cp
                intervalEnd = cp
                prevValue = cp.uLabel_to_s(@myUnicode)
              end
            end
          end
          f.print endTable
          f.print endSection
        end
        f.print endSection
      end
       if(kind == "allsc")
        f.print startDocument
        cp = @myUnicode.codepoint(0x0000)
        f.print startSection
        f.print startHeader + "Codepoints by script" + endHeader
    
        @myScripts.keys.sort.each do |s|
          aScript = @myUnicode.script(s)
          if(aScript.to_s.length < 1)
            next
          end
          f.print startSection
          f.print startHeader + q(aScript.to_s) + endHeader
          f.print startTable
          f.print startRow
          f.print startHColumn + "Code(s)" + endHColumn
          if(self.class == HTMLDocument)
            f.print startHColumn + "Char" + endColumn
          end
          f.print startHColumn + "U-label" + endHColumn
          f.print startHColumn + "Rules" + endHColumn
          if(self.class == HTMLDocument)
            f.print startHColumn + "GC" + endColumn
          end
          f.print startHColumn + "Name(s)" + endHColumn
          f.print endRow
          aScript.codepoints.sort.each do |c|
            if(c >= @myStart && c <= @myEnd)
              cp = @myUnicode.codepoint(c)
              row = startRow
              row += startColumn + cp.to_s + endColumn
              if(self.class == HTMLDocument)
                row += startColumn + "&#x" + cp.to_s.sub("U+","") + ";" + endColumn
              end
              row += startColumn + cp.uLabel_to_s(@myUnicode) + endColumn
              row += startColumn + cp.rules_to_s(@myUnicode) + endColumn
              row += startColumn + cp.generalCategory + endColumn          
              row += startColumn + q(cp.name) + endColumn
              f.print row
              f.print endRow + "\n"
              intervalStart = cp
              intervalEnd = cp
              prevValue = cp.uLabel_to_s(@myUnicode)
            end
          end
          f.print endTable
          f.print endSection
        end
        f.print endSection
      end
      if(kind == "UCD")
        f.print startSection
        f.print startHeader + "Codepoints in Unicode Character Database (UCD) format" + endHeader
        f.print startPre
        intervalStart = nil
        intervalEnd = nil
        prevValue = ""
        (@myStart..@myEnd).each do |c|
          cp = @myUnicode.codepoint(c)
          if(intervalStart == nil)
            intervalStart = cp
            intervalEnd = cp
            prevValue = cp.uLabel_to_s(@myUnicode)
          end
          if(cp.uLabel_to_s(@myUnicode) != prevValue || c == @myEnd)
            if(intervalStart == intervalEnd)
              ss = intervalStart.to_s.sub("U+","")
              tt = intervalStart.name
            else
              ss = intervalStart.to_s.sub("U+","") + ".." + intervalEnd.to_s.sub("U+","")
              tt = intervalStart.name + ".." + intervalEnd.name
            end
            (1..(12-ss.length)).each { ss += " "}
            ss += "; " + prevValue
            (1..(12-prevValue.length)).each { ss += " "}
            ss += "# " + tt
            f.print q(ss[0..71]) # Truncate the string if the lines are too long
            f.print lineBreak
            intervalStart = cp
            intervalEnd = cp
            prevValue = cp.uLabel_to_s(@myUnicode)
          else
            intervalEnd = cp
          end
        end
        f.print endPre
        f.print endSection
        f.print endDocument
      end
      if(kind == "ALL")
        f.print startSection
        f.print startHeader + "Codepoints in Unicode Character Database" + endHeader
        f.print startPre
        (@myStart..@myEnd).each do |c|
          cp = @myUnicode.codepoint(c)
          ss = cp.to_s.sub("U+","")
          ss += ";" + cp.uLabel_to_s(@myUnicode)
          ss += ";" + cp.inOldIDNA(@myUnicode)
          ss += ";" + cp.rules_to_s(@myUnicode)
          ss += ";" + cp.name
          f.print ss
          f.print lineBreak
        end
        f.print endPre
        f.print endSection
        f.print endDocument
      end
    end
  end

  def q(s)
    t = s
    t.gsub!("<","&lt;")
    t.gsub!(">","&gt;")
    return(t)
  end
  def startSection
    return ""
  end
  def endSection
    return ""
  end
  def startHeader
    return ""
  end
  def endHeader
    return "\n"
  end
  def startTable
    return ""
  end
  def endTable
    return ""
  end
  def startRow
    return ""
  end
  def endRow
    return ""
  end
  def startColumn
    return ""
  end
  def endColumn
    return ""
  end
  def startHColumn
    return ""
  end
  def endHColumn
    return ""
  end
end

class HTMLDocument < Document
  def startDocument
    return "<HTML>\n<BODY>\n"
  end
  def endDocument
    return "</BODY>\n</HTML>\n"
  end
  def startPre
    return "<PRE>\n"
  end
  def endPre
    return "</PRE>\n"
  end
  def lineBreak
    return "<BR/>\n"
  end
  def startList
    return "<UL>\n"
  end
  def endList
    return "</UL>\n"
  end
  def startListItem
    return "<LI>"
  end
  def endListItem
    return "</LI>\n"
  end
  def startSection
    return ""
  end
  def endSection
    return ""
  end
  def startHeader
    return "<H3>"
  end
  def endHeader
    return "</H3>\n"
  end
  def startTable
    return "<TABLE border=1>"
  end
  def endTable
    return "</TABLE>\n"
  end
  def startRow
    return "<TR>"
  end
  def endRow
    return "</TR>\n"
  end
  def startColumn
    return "<TD>"
  end
  def endColumn
    return "</TD>"
  end
  def startHColumn
    return "<TH>"
  end
  def endHColumn
    return "</TH>"
  end
end

class XMLRFCDocument < Document
  def startDocument
    return ""
  end
  def endDocument
    return ""
  end
  def startSection
    return ""
  end
  def endSection
    return "</section>\n"
  end
  def startPre
    return "<figure><artwork>\n"
  end
  def endPre
    return "</artwork></figure>"
  end
  def lineBreak
    return "\n"
  end
  def startList
    return "<list style=\"symbols\">\n"
  end
  def endList
    return "</list>\n"
  end
  def startListItem
    return "<t>"
  end
  def endListItem
    return "</t>\n"
  end
  def startHeader
    return "<section title=\""
  end
  def endHeader
    return "\">\n"
  end
  def startTable
    return "<texttable>"
  end
  def endTable
    return "</texttable>\n"
  end
  def startRow
    return ""
  end
  def endRow
    return "\n"
  end
  def startColumn
    return "<c>"
  end
  def endColumn
    return "</c>"
  end
  def startHColumn
    return "<ttcol>"
  end
  def endHColumn
    return "</ttcol>"
  end
end

class TextDocument < Document
  def startDocument
    return ""
  end
  def endDocument
    return ""
  end
  def startSection
    return ""
  end
  def endSection
    return ""
  end
  def startPre
    return ""
  end
  def endPre
    return ""
  end
  def lineBreak
    return "\n"
  end
  def startList
    return ""
  end
  def endList
    return ""
  end
  def startListItem
    return ""
  end
  def endListItem
    return "\n"
  end
  def startHeader
    return ""
  end
  def endHeader
    return "\n"
  end
  def startTable
    return ""
  end
  def endTable
    return "\n"
  end
  def startRow
    return ""
  end
  def endRow
    return "\n"
  end
  def startColumn
    return ""
  end
  def endColumn
    return ""
  end
  def startHColumn
    return ""
  end
  def endHColumn
    return ""
  end
end

directory = Dir.pwd
examples = false
initialize = false

ARGV.each do |whatever|
  a = whatever
  if(a == "-e")
    examples = true
  elsif(a == "-i")
    initialize = true
  elsif(a == "-h")
    print("Version 0.0.1\n")
    print("The following files are needed\n")
    print("UnicodeData.txt\n")
    print("CaseFolding.txt\n")
    print("Blocks.txt\n")
    print("Scripts.txt\n")
    print("PropList.txt\n")
    print("DerivedCoreProperties.txt\n")
    print("CompositionExclusions.txt\n")
    print("DerivedGeneralCategory.txt\n")
    print("HangulSyllableType.txt\n")
    print("You can find the files at for example http://www.unicode.org/Public/6.1.0/ucd/\n")
    print("...or subdirectory to a path similar to that.\n")
    print("It is ok to give files like named above but in beta version like UnicodeData-6.1.0d8.txt.\n")
    print("Usage: createtables.rb [-h] [-e] [-i] [directory]\n")
    exit(1)
  else
    directory = a
  end
end

if(directory[-1,1] != "/")
  directory = directory + "/"
end

if(initialize)
  print("Removing cache\n")
  File::unlink(directory + "unicode.cache")
end

print("Looking in directory " + directory + "\n")

u = Unicodedata.new(directory)

def check(u,c)
  cp = u.codepoint(c)
  printf "%s: %s\n",cp.to_s,cp.uLabel_to_s(u)
  print cp.inOldIDNA(u) + ":" + cp.pretty(u) + "\n"
end

if(examples)
  check(u,0x1D400)
  check(u,0x41)
  check(u,0x61)
  check(u,0xFA10)
  check(u,0x00DF)
  check(u,0x1100)
  check(u,0xE000)
  check(u,0x302E)
  check(u,0xAC00)

  check(u,0x302D)
  check(u,0x302E)
  check(u,0x302F)
  check(u,0x3030)

  check(u,0x2064)
  check(u,0x2065)
  check(u,0xFFF8)
  check(u,0xffff)

  check(u,0x0133)
  nfkccp = u.nfkc([0x0133])
  print "nfkc(0x0133): "
  nfkccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  nfkccp = u.nfkd([0x0133])
  print "nfkd(0x0133): "
  nfkccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  check(u,0x01D6)
  nfkccp = u.nfkc([0x01D6])
  print "nfkc(0x01D6): "
  nfkccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  check(u,0x00AF)
  nfkccp = u.nfkc([0x00AF])
  print "nfkc(0x00AF): "
  nfkccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  check(u,0x03D3)
  nfkccp = u.nfkc([0x03D3])
  print "nfkc(0x03D3): "
  nfkccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  check(u,0x10000)
  print "Category A\n"
  check(u,0x3005)
  check(u,0x3007)
  check(u,0x3400)
  check(u,0x20000)
  print "\n"
  print "Category B\n"
  check(u,0x3038)
  check(u,0xFA22)
  print "\n"
  print "Category C\n"
  check(u,0x2E80)
  check(u,0x2E9B)
  check(u,0x2EA0)
  check(u,0x3021)
  check(u,0x303B)
  print "\n"
  check(u,0x200D)
  check(u,0x200C)
  check(u,0x140)
  print "\n"
  check(u,0x2800)
  print "\n"
  check(u,0x07B2)
  print "\n"
  check(u,0x03C2)
  check(u,0x037A)
  check(u,0x03AA)
  check(u,0x03F0)
  check(u,0x0133)
  
  check(u,0x0041)
  
  check(u,0xFF41)
  nfkccp = u.nfkc([0xFF41])
  print "nfkc(0xFF41): "
  nfkccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfkccp = u.nfkc([0x037A])
  print "nfkc(0x037A): "
  nfkccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfkdcp = u.nfkd([0x037A])
  print "nfkd(0x037A): "
  nfkdcp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfdcp = u.nfd([0x037A])
  print "nfd(0x037A): "
  nfdcp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfccp = u.nfc([0x037A])
  print "nfc(0x037A): "
  nfccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfkccp = u.nfkc([0x03AA])
  print "nfkc(0x03AA): "
  nfkccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfkdcp = u.nfkd([0x03AA])
  print "nfkd(0x03AA): "
  nfkdcp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfdcp = u.nfd([0x03AA])
  print "nfd(0x03AA): "
  nfdcp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfccp = u.nfc([0x03AA])
  print "nfc(0x03AA): "
  nfccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfkccp = u.nfkc([0x03F0])
  print "nfkc(0x03F0): "
  nfkccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfkdcp = u.nfkd([0x03F0])
  print "nfkd(0x03F0): "
  nfkdcp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfdcp = u.nfd([0x03F0])
  print "nfd(0x03F0): "
  nfdcp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
  
  nfccp = u.nfc([0x03F0])
  print "nfc(0x03F0): "
  nfccp.each do |thec|
    print u.codepoint(thec).to_s + " "
  end
  print "\n"
end

print "Generating xmlrfc.txt\n"
d = XMLRFCDocument.new(directory + "xmlrfc.xml",u,0x00,0x10FFFF,"UCD")
print directory + "xmlrfc.xml done!\n"

print "Generating codepoints.txt\n"
d = TextDocument.new(directory + "allcodepoints.txt",u,0x00,0x10FFFF,"ALL")
print directory + "codepoints.txt done!\n"

print "Generating byscript.html\n"
d = HTMLDocument.new(directory + "byscript.html",u,0x00,0x10FFFF,"allsc")
print directory + "byscript.html done!\n"

print "Generating bygc.html\n"
d = HTMLDocument.new(directory + "bygc.html",u,0x00,0x10FFFF,"allgc")
print directory + "bygc.html done!\n"
