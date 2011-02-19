#--
# CiteProc-Ruby
# Copyright (C) 2009-2011 Sylvester Keil <sylvester.keil.or.at>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.	If not, see <http://www.gnu.org/licenses/>.
#++

module CiteProc


  # == CiteProc::Data
  #
  # A minimal citation data object, used as input by both the
  # processCitationCluster() and appendCitationCluster() command, has the
  # following form:
  #
  # {
  #    "citationItems": [ { "id": "ITEM-1" } ],
  #    "properties": {"noteIndex": 1 }
  # }
  #
  # The citationItems array is a list of one or more citation item objects,
  # each containing an id used to retrieve the bibliographic details of the
  # target resource. A citation item object may contain one or more
  # additional optional values:
  #
  # * locator: a string identifying a page number or other pinpoint location
  #   or range within the resource;
  # * label: a label type, indicating whether the locator is to a page, a
  #   chapter, or other subdivision of the target resource. Valid labels are
  #   defined in the link CSL specification.
  # * suppress-author: if true, author names will not be included in the
  #   citation output for this cite;
  # * author-only: if true, only the author name will be included in the
  #   citation output for this cite -- this optional parameter provides a
  #   means for certain demanding styles that require the processor output
  #   to be divided between the main text and a footnote.
  # * prefix: a string to print before this cite item;
  # * suffix: a string to print after this cite item.
  #
  # In the properties portion of a citation, the noteIndex value indicates
  # the footnote number in which the citation is located within the
  # document. Citations within the main text of the document have a
  # noteIndex of zero.
  #
  # The processor will add a number of data items to a citation during
  # processing. Values added at the top level of the citation structure
  # include:
  #
  # * citationID: A unique ID assigned to the citation, for internal use by
  #   the processor. This ID may be assigned by the calling application, but
  #   it must uniquely identify the citation, and it must not be changed
  #   during processing or during an editing session.
  # * sortedItems: This is an array of citation objects and accompanying
  #   bibliographic data objects, sorted as required by the configured
  #   style. Calling applications should not need to access the data in this
  #   array directly.
  #
  # Values added to individual citation item objects may include:
  #
  # * sortkeys: an array of sort keys used by the processor to produce the
  #   sorted list in sortedItems. Calling applications should not need to
  #   touch this array directly.
  # * position: an integer flag that indicates whether the cite item should
  #   be rendered as a first reference, an immediately-following reference
  #   (i.e. ibid), an immediately-following reference with locator
  #   information, or a subsequent reference.
  # * first-reference-note-number: the number of the noteIndex of the first
  #   reference to this resource in the document.
  # * near-note: a boolean flag indicating whether another reference to this
  #   resource can be found within a specific number of notes, counting back
  #   from the current position. What is "near" in this sense is
  #   style-dependent.
  # * unsorted: a boolean flag indicating whether sorting imposed by the
  #   style should be suspended for this citation. When true, cites are
  #   rendered in the order in which they are presented in citationItems.
  #
  class CitationData
    include Attributes
    
    attr_fields %w{ citation-id citation-items properites sorted-items }

    
    def initialize(attributes={})

      self.key_filter = Hash.new do |hash, key|
        hash[key] = key.to_s.gsub(/([[:lower:]])([[:upper:]])/, '\1-\2').downcase
      end

      self.merge!(attributes)
      
      yield self if block_given?
    end
    
    # @returns a list of citation data
    def self.parse(argument)
      return [] if argument.nil?
      argument = [argument] unless argument.kind_of?(Array)
      argument.map { |d| CitationData.new(d) }
    end
    
    #
    # Merges the argument into the citation data. The argument can be a list
    # of citation items (hashes), a single citation item (hash), another
    # citation data instance or hash, or a single id of a citation item.
    #
    def merge!(argument)
      case
      when argument.is_a?(Array)
        super('citation-items' => argument)
      
      when argument.is_a?(Hash)
        argument.has_key?('id') ? super('citation-items' => [argument]) : super(argument)
        
      when argument.is_a?(String) || argument.is_a?(Symbol)
        super('citation-items' => [{ 'id' => argument.to_s }])

      when argument.is_a?(CitationData)
        super(argument.attributes)

      else
        raise(ArgumentError, "unable to merge #{argument.inspect} into citation data")
      end
    end
    
    def citation_items
      self.attributes['citation-items'] ||= []
    end
    
    def properties
      self.attributes['properties'] ||= {}
    end
    
    [[:items, :citation_items], [:id, :citation_id]].each do |a, m|
      alias_method a, m
      alias_method "#{a}=", "#{m}="
      alias_method "#{a}?", "#{m}?"
    end
    
    [:each, :map, :empty?].each do |method_id|
      define_method method_id do |*args, &block|
        self.items.send(method_id, *args, &block)
      end
    end
    
  end
  
end