require 'prawn'
require 'base64'
require 'active_support'
require 'active_support/core_ext/object'

class SignaturePdf

  # dir is the tmp directory that the filler is working in
  # 
  def self.make(params, path)
    i = self.new
    i.params = params
    i.path = path
    i.make
  end

  attr_accessor :params, :path

  def make 
    write_images
    place_images
    render_file
  end

  private

  def render_file
    pdf.render_file(path.join('signatures.pdf'))
  end

  def place_images
    # canvas ignores the default margins which mess with the alignment of the two PDFs we're going to end up merging.
    pdf.canvas do 
      if File.exist?(signature_path)
        pdf.image(signature_path, at: signature_position, fit: signature_fit)
      end

      if File.exist?(driver_sig_path)
        pdf.image(driver_sig_path, at: driver_sig_position, fit: driver_sig_fit)
      end
    end
  end

  def write_images
    if signature_content.present?
      File.open(signature_path, 'wb') { |f| f.write(Base64.decode64(signature_content)) }
    end
    if driver_sig_content.present?
      File.open(driver_sig_path, 'wb') { |f| f.write(Base64.decode64(driver_sig_content)) }
    end
  end

  # 
  # Coordinates extracted using the python script in the utilities folder
  # 


  # X and Y coordinates in an array to place the signature. In the included form this is currently:
  # [100, 209] 
  # 
  def signature_position
    @signature_position ||= params.dig("signature", "position").map(&:to_i)
  end

  # X and Y coordinates in an array to place the signature. In the included form this is currently:
  # [93, 74]
  # 
  def driver_sig_position
    @driver_sig_position ||= params.dig("driver_signature", "position").map(&:to_i)
  end

  # Width and Height to fit the signature within. Currently:
  # [350, 29]
  # 
  def signature_fit
    @signature_fit ||= params.dig("signature", "fit").map(&:to_i)
  end
  # Width and Height to fit the signature within. Currently:
  # [319, 29]
  # 
  def driver_sig_fit
    @driver_sig_fit ||= params.dig("driver_signature", "fit").map(&:to_i)
  end

  def signature_content
    params.dig("signature", "content")
  end

  def driver_sig_content
    params.dig("driver_signature", "content")
  end

  def signature_path
    path.join("signature.png")
  end

  def driver_sig_path
    path.join("driver_signature.png")
  end

  def pdf
    @pdf ||= new_pdf
  end

  # Make a new Prawn::Document with 2 pages.
  # The form we're filling out and merging with is always 2 pages long.
  # 
  def new_pdf
    new_pdf = Prawn::Document.new(:page_size => "LETTER")
    new_pdf.start_new_page
    new_pdf
  end

  
end