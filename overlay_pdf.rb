require 'prawn'
require 'base64'
require 'rmagick'
require 'net/http'
require 'active_support'
require 'active_support/core_ext/object'

class OverlayPdf

  # dir is the tmp directory that the filler is working in
  # 
  def self.make(params, path)
    i = self.new
    i.params = params
    i.path = path
    i.make
  end

  attr_accessor :params, :path
  attr_reader :page_1_keys, :page_2_keys

  def initialize
    @page_1_keys, @page_2_keys = am_pm_positions.keys.partition { |k| k.match(/\d/).to_s.to_i <= 3}
  end

  def make 
    mark_am_pm
    retrieve_signature_files
    place_images
    render_file
    true
  end

  private

  def render_file
    pdf.render_file(path.join('overlays.pdf'))
  end

  def mark_am_pm
    mark_first_page_am_pm
    mark_second_page_am_pm
  end

  def mark_first_page_am_pm
    self.page_1_keys.each do |key|
      if params[key] == true
        stroke_box(key)
      end
      params.delete(key)
    end
  end

  def mark_second_page_am_pm
    self.page_2_keys.each do |key|
      if params[key] == true
        if pdf.page_count == 1
          pdf.start_new_page
        end
        stroke_box(key)
      end
      params.delete(key)
    end
  end

  def stroke_box(key)
    coords = am_pm_positions[key]
    pdf.canvas do 
      pdf.stroke do 
        pdf.rounded_rectangle [coords[:x], coords[:y]], coords[:w], coords[:h], 2
      end
    end
  end

  def place_images
    # Signatures are always on page 2
    # We or may not have created a page 2 depending on the number of trips
    if pdf.page_count == 1
      pdf.start_new_page
    end
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

  def retrieve_signature_files
    write_images
    download_images
    verify_images
    trim_images
  end

  def write_images
    if signature_content.present?
      File.open(signature_path, 'wb') { |f| f.write(Base64.decode64(signature_content)) }
    end

    if driver_sig_content.present?
      File.open(driver_sig_path, 'wb') { |f| f.write(Base64.decode64(driver_sig_content)) }
    end
  end

  def download_images
    if signature_url.present?
      download(signature_url, signature_path)
    end

    if driver_sig_url.present?
      download(driver_sig_url, driver_sig_path)
    end
  end

  # If we're missing a signature abort now
  # 
  def verify_images
    raise SignaturePdf::SignatureError, "Missing Member Signature" unless File.exist?(signature_path)
    raise SignaturePdf::SignatureError, "Missing Driver Signature" unless File.exist?(driver_sig_path)
  end

  # Remove any extra whitespace and the background if possible to make them fit better
  # 
  def trim_images 
    trim_signature(signature_path)
    trim_signature(driver_sig_path)
  end

  def trim_signature(path_to_file)
    image = Magick::Image.read(path_to_file).first
    image.trim!
    image.format = "PNG"
    image.fuzz = '10%'
    bg_color = image.background_color
    image.paint_transparent(bg_color, alpha: 0).write(path_to_file)
  rescue Magick::ImageMagickError => e
    raise SignaturePdf::SignatureError, "#{path_to_file} error: #{e}"
  end

  # Download without loading into memory
  # See: https://ruby-doc.org/stdlib-2.6.5/libdoc/net/http/rdoc/Net/HTTP.html#class-Net::HTTP-label-Streaming+Response+Bodies
  # 
  def download(url, out_path)
    uri = URI(url)

    use_ssl = url.start_with?('https://')

    Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl) do |http|
      request = Net::HTTP::Get.new uri

      http.request request do |response|
        open out_path, 'w' do |io|
          response.read_body do |chunk|
            io.write chunk
          end
        end
      end
    end
  rescue StandardError => e 
    raise SignaturePdf::SignatureError, "Failed to download #{url} with error: #{e}"
  end
  # 
  # Coordinates extracted using the python script in the utilities folder
  # TODO: We should actually be able to read these positions out of the PDF document so they don't need to be passed in.
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

  def signature_url
    params.dig("signature", "url")
  end

  def driver_sig_url
    params.dig("driver_signature", "url")
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

  def new_pdf
    Prawn::Document.new(:page_size => "LETTER")
  end

  def am_pm_positions 
    {
      'pickup_am_1' => { :x => 456, :y => 570, :w => 15, :h => 10 }, 
      'pickup_am_2' => { :x => 456, :y => 371, :w => 16, :h => 10 }, 
      'pickup_am_3' => { :x => 456, :y => 199, :w => 15, :h => 10 }, 
      'pickup_am_4' => { :x => 456, :y => 717, :w => 15, :h => 10 }, 
      'pickup_am_5' => { :x => 456, :y => 551, :w => 15, :h => 10 }, 
      'pickup_am_6' => { :x => 456, :y => 380, :w => 15, :h => 10 }, 
      'dropoff_am_1' => { :x => 456, :y => 519, :w => 16, :h => 10 }, 
      'dropoff_am_2' => { :x => 456, :y => 323, :w => 16, :h => 10 }, 
      'dropoff_am_3' => { :x => 456, :y => 151, :w => 16, :h => 10 }, 
      'dropoff_am_4' => { :x => 456, :y => 663, :w => 16, :h => 10 }, 
      'dropoff_am_5' => { :x => 456, :y => 493, :w => 16, :h => 10 }, 
      'dropoff_am_6' => { :x => 456, :y => 330, :w => 16, :h => 10 }, 
      'pickup_pm_1' => { :x => 474, :y => 570, :w => 16, :h => 10 }, 
      'pickup_pm_2' => { :x => 474, :y => 371, :w => 16, :h => 10 }, 
      'pickup_pm_3' => { :x => 474, :y => 199, :w => 16, :h => 10 }, 
      'pickup_pm_4' => { :x => 474, :y => 717, :w => 16, :h => 10 }, 
      'pickup_pm_5' => { :x => 474, :y => 551, :w => 16, :h => 10 }, 
      'pickup_pm_6' => { :x => 474, :y => 380, :w => 16, :h => 10 }, 
      'dropoff_pm_1' => { :x => 474, :y => 519, :w => 16, :h => 10 }, 
      'dropoff_pm_2' => { :x => 474, :y => 323, :w => 16, :h => 10 }, 
      'dropoff_pm_3' => { :x => 474, :y => 151, :w => 16, :h => 10 }, 
      'dropoff_pm_4' => { :x => 474, :y => 664, :w => 16, :h => 10 }, 
      'dropoff_pm_5' => { :x => 474, :y => 492, :w => 16, :h => 10 }, 
      'dropoff_pm_6' => { :x => 474, :y => 330, :w => 16, :h => 10 }, 
    }
  end

  class SignatureError < StandardError
  end
  
end