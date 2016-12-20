class BatchesController < ApplicationController
  
  def index
    @batches = Batch.all.order(:created_at => :desc)
  end

  def create
    if @batch = Batch.create(batch_params)
      redirect_to :back
    else
      render text: @batch.errors.inspect
    end
  end

  def print_labels
    @batch = Batch.find(params[:id])
    @batch.print_labels!

    respond_to do |format|
      format.html { redirect_back fallback_location: '/' }
      format.js  { render :nothing => true, :status => 200 }
    end    
  end

  def test_label
    line_item = Batch.first.line_items_for_printing.first
    html = ApplicationController.render(:partial => "batches/label", :locals => line_item)
    kit = PDFKit.new(html, 
      :page_height => "50.8mm", 
      :page_width => "101.6mm", 
      :margin_top => "0mm",
      :margin_right => "0mm",
      :margin_bottom => "0mm",
      :margin_left => "0mm"
    )

    respond_to do |format|
      format.pdf do
        send_data kit.to_pdf, :filename => "label.pdf"
      end
    end
  end

  private

    def batch_params
      params.require(:batch).permit(:csv_original)
    end
end
