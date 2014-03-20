module Tgios
  class XMLParser

    attr_reader :s3_key

    def initialize
      @nsxmlparser = nil
      @events = {}
      @key = nil
    end

    def parse_xml(nsxmlparser_object,key_name,event_name, &block)
      @nsxmlparser = nsxmlparser_object
      @key = key_name
      @events[event_name] = block

      delegate_parser
      self
    end

    def delegate_parser
      @nsxmlparser.delegate = self
      @nsxmlparser.parse
      s3_key = @nsxmlparser.delegate.s3_key
      @events[:delegate].call(s3_key) unless @events[:delegate].nil?
    end

    def parser(parser, didStartElement:elementName, namespaceURI:namespaceURI, qualifiedName:qualifiedName, attributes:attributeDict)
      if elementName == @key
        @scan_key = true
        @s3_key = ''

      end
    end

    def parser(parser, didEndElement:elementName, namespaceURI:namespaceURI, qualifiedName:qName)
      if elementName == @key
        @scan_key = false
        parser.abortParsing
      end
    end

    def parser(parser, foundCharacters:string)
      @s3_key += string if @scan_key
    end

  end
end