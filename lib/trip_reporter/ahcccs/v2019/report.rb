require 'pdf_forms'
require 'base64'

class TripReporter::Ahcccs::V2019::Report
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
    raise TripReporter::FillError, "Missing template file" unless File.exist?(template_path)

    Dir.mktmpdir do |dir|
      self.path = Pathname.new(dir)
      if result && !self.errors.any?
        { pdf: result }
      else
        { error: self.errors }
      end
    end
  end

  private

  def result
    @result ||= make_result
  end

  def make_result
    create_overlay_pdf # Make the overlay PDF first to remove any unneeded keys
    if fill_form
      if add_overlays
        return encode
      end
    end
    false
  end

  # PDFtk doesn't know how to deal with images so we're creating a PDF with Prawn
  # that contains the overlays and then merging the two together
  # Return true because pdftk doesn't return anything on success, but will raise if there is an error
  #
  def add_overlays
    if File.exist?(overlays_path)
      pdftk.multistamp(flattened_path, overlays_path, final_path)
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

  def overlays_path
    path.join('overlays.pdf')
  end

  def final_path
    path.join('final.pdf')
  end

  def template_path
    Pathname.new(File.dirname(File.expand_path(__FILE__))).join('assets','form_template.pdf')
  end

  def create_overlay_pdf
    TripReporter::Ahcccs::V2019::OverlayPdf.make(params, path)
  rescue TripReporter::OverlayError => e
    self.errors << e
    false
  end
end