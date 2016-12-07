require 'sinatra'
require 'csv'

get '/' do
  erb :index
end

post '/' do
  parsed_csv = CSV.read(params[:file])
  

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

  content_type 'application/csv'
  attachment   'data.csv'

  CSV.generate do |csv|
    csv << header_row

    # Insert rows without blank item locations
    parsed_csv.each { |r| csv << r unless r[item_location_column_index].to_s == "" }

    # Insert rows with blank item locations
    parsed_csv.each { |r| csv << r if r[item_location_column_index].to_s == ""  }    
  end
end