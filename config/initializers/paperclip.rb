# Paperclip.options[:content_type_mappings] = { csv: 'application/vnd.ms-excel' }
Paperclip.options[:content_type_mappings] = {:csv => ["text/comma-separated-values", "text/csv"]}