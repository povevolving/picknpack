# Monkey patching because this gem's code sucks
module PrintNode
  class PrintJob
    def to_hash
      hash = {}
      hash['printerId'] = @printer_id
      hash['title'] = @title
      hash['contentType'] = @content_type
      hash['content'] = @content
      hash['source'] = @source
      hash
    end
  end
end