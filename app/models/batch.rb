require 'csv'

class Batch < ApplicationRecord
  has_attached_file :csv_original
  has_attached_file :csv_processed

  validates_attachment_content_type :csv_original, :not => %w(application/exe)
  validates_attachment_content_type :csv_processed, :not => %w(application/exe)

  def process_original_csv!

    csv_string = Paperclip.io_adapters.for(csv_original).read
    parsed_csv = CSV.parse(csv_string)

    # Remove header row, assign indexes
    header_row = parsed_csv.shift
    order_number_column_index = header_row.index("Order - Number")
    item_location_column_index = header_row.index("Item - Location") + 1
    shelf_column_index = order_number_column_index + 1

    # Add Shelf to header
    header_row.insert(shelf_column_index, "Shelf")

    # Sort by order number
    parsed_csv.sort!{ |a,b| b[order_number_column_index].to_i <=> a[order_number_column_index].to_i }

    # Start with first order ID
    current_order_id = parsed_csv[0][order_number_column_index]
    current_shelf_number = 1

    parsed_csv.map! do |line_item|

      if line_item[order_number_column_index] != current_order_id
        current_shelf_number += 1
        current_order_id = line_item[order_number_column_index]
      end

      line_item.insert(shelf_column_index, current_shelf_number)
    end

    parsed_csv.sort!{ |a,b| a[item_location_column_index].to_s <=> b[item_location_column_index].to_s }

    generated_csv = CSV.generate do |csv|
      csv << header_row

      # Insert rows without blank item locations
      parsed_csv.each { |r| csv << r unless r[item_location_column_index].to_s == "" }

      # Insert rows with blank item locations
      parsed_csv.each { |r| csv << r if r[item_location_column_index].to_s == ""  }    
    end

    self.csv_processed = StringIO.new(generated_csv)
    self.csv_processed_file_name = csv_original.original_filename.gsub(/\.csv/, '_processed.csv')
    save
  end

  def print_labels!
    
    line_items = line_items_for_printing

    auth = PrintNode::Auth.new("dc4d7e31c7fac62d29cf9c833a7b8f793cc833fb")
    client = PrintNode::Client.new(auth)

    my_printer_id = 196762 #client.printers[0].id

    options = {} #For options argument in create_printjob
    options['options'] = {'bin' => '1'}
    options['expireAfter'] = 120000
    options['qty'] = 1

    line_items[0...3].each do |line_item|

      html = ApplicationController.render(:partial => "batches/label", :locals => line_item)

      kit = PDFKit.new(html, 
        :page_height => "50.8mm", 
        :page_width => "101.6mm", 
        :margin_top => "0mm",
        :margin_right => "0mm",
        :margin_bottom => "0mm",
        :margin_left => "0mm"
      ) # kit.to_pdf

      my_printjob_info = PrintNode::PrintJob.new(my_printer_id, 'Krewella Test Label', 'pdf_base64', Base64.encode64(kit.to_pdf), 'PicknPack')

      #Now we can create our printjob.
      my_printjob = client.create_printjob(my_printjob_info,options)

      #We can now see our our the information of our printjob using the id we got from create_printjob.
      my_printjob_info = client.printjobs(my_printjob)
    end

    update_attribute :label_printed, true
  end

  def line_items_for_printing
    csv_string = Paperclip.io_adapters.for(csv_processed).read
    parsed_csv = CSV.parse(csv_string)

    header_row = parsed_csv.shift
    
    index_item_name = header_row.index("Item - Name")
    index_item_quantity = header_row.index("Item - Qty")
    index_item_sku = header_row.index("Item - SKU")
    index_shelf = header_row.index("Shelf")
    index_order_number = header_row.index("Order - Number")
    index_item_location = header_row.index("Item - Location")
    index_item_image = header_row.index("Item - Image URL")

    parsed_csv.map do |line|
      {
        item_name: line[index_item_name],
        item_quantity: line[index_item_quantity],
        item_sku: line[index_item_sku],
        shelf: line[index_shelf],
        order_number: line[index_order_number],
        item_location: line[index_item_location],
        item_image: line[index_item_image]
      }
    end
  end
end