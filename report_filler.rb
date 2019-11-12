require 'pdf_forms'
require 'base64'
require_relative 'signature_pdf'


class ReportFiller
  attr_accessor :params, :path, :errors

  def self.fill(params)
    i = self.new
    i.params = params
    i.fill
  end

  def initialize
    self.errors = []
  end

  def fill
    raise ReportFiller::FillError, "Missing template file" unless File.exist?(template_path)
    
    Dir.mktmpdir do |dir|
      self.path = Pathname.new(dir)
      if result && !self.errors.any?
        { pdf: result }
      else
        { error: self.errors }
      end
    end
  end

  # required_params( 
  #   :company_address, 
  #   :drivers_name, 
  #   :date, 
  #   :vehicle_number, 
  #   :vehicle_make_color,
  #   :ahcccs_id,
  #   :ahcccs_id_2,
  #   :dob,
  #   :dob_2,
  #   :member_name,
  #   :member_name_2,
  #   :mailing_address,
  #   :pickup_address_1,
  #   :pickup_time_1,
  #   :pickup_odometer_1,
  #   :dropoff_address_1,
  #   :dropoff_time_1,
  #   :dropoff_odometer_1,
  #   :reason_for_visit_1,
  #   :signature,
  #   :driver_signature,
  #   :signature_date)

  private

  def result
    @result ||= make_result
  end

  def make_result
    if fill_form
      if add_signatures
        return encode
      end
    end
    false
  end

  # PDFtk doesn't know how to deal with images so we're creating a PDF with Prawn
  # that contains the signatures and then merging the two together
  # Return true because pdftk doesn't return anything on success, but will raise if there is an error
  # 
  def add_signatures
    if create_signature_pdf
      pdftk.multistamp(flattened_path, signatures_path, final_path)
      true
    end
  rescue PdfForms::PdftkError => e
    self.errors << e
    false
  end

  # The response should be a json object with the PDF base64 encoded
  # Or an error if there was a problem
  # 
  def encode
    Base64.encode64(File.open(final_path, "rb").read)
  rescue StandardError => e
    self.errors << e
    false
  end

  # Use PDFtk to fill in the form fields and remove the form from the PDF
  # Return true because pdftk doesn't return anything on success, but will raise if there is an error
  # 
  def fill_form
    pdftk.fill_form(template_path, flattened_path, self.params, :flatten => true)
    true
  rescue PdfForms::PdftkError => e
    self.errors << e
    false
  end

  def pdftk
    @pdftk ||= PdfForms.new('/usr/bin/pdftk')
  end

  def flattened_path
    path.join('flattened_form.pdf')
  end

  def signatures_path
    path.join('signatures.pdf')
  end

  def final_path
    path.join('final.pdf')
  end

  def template_path
    Pathname.new(File.dirname(File.expand_path(__FILE__))).join('assets','form_template.pdf')
  end

  def create_signature_pdf
    SignaturePdf.make(params, path)
  rescue SignaturePdf::SignatureError => e 
    self.errors << e
    false
  end

  class ReportFiller::FillError < StandardError
  end
end