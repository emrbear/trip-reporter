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
    page_1_am_pm.keys.each do |key|
      if params[key] == true
        stroke_box(key)
      end
      params.delete(key)
    end
  end

  def mark_second_page_am_pm
    page_2_am_pm.keys.each do |key|
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
        pdf.rounded_rectangle [coords['x'], coords['y']], coords['w'], coords['h'], 2
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
    raise OverlayPdf::SignatureError, 'Missing Member Signature' unless File.exist?(signature_path)
    raise OverlayPdf::SignatureError, 'Missing Driver Signature' unless File.exist?(driver_sig_path)
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
    image.format = 'PNG'
    image.fuzz = '10%'
    bg_color = image.background_color
    image.paint_transparent(bg_color, alpha: 0).write(path_to_file)
  rescue Magick::ImageMagickError => e
    raise OverlayPdf::SignatureError, "#{path_to_file} error: #{e}"
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
    raise OverlayPdf::SignatureError, "Failed to download #{url} with error: #{e}"
  end



  # X and Y coordinates in an array to place the signature.
  #
  def signature_position
    @signature_position ||= [positions.dig('page_2', 'signature', 'x'), positions.dig('page_2', 'signature', 'y')]
  end

  # X and Y coordinates in an array to place the signature. In the included form this is currently:
  #
  def driver_sig_position
    @driver_sig_position ||= [positions.dig('page_2', 'driver_signature', 'x'), positions.dig('page_2', 'driver_signature', 'y')]
  end

  # Width and Height to fit the signature within. Currently:
  #
  def signature_fit
    @signature_fit ||= [positions.dig('page_2', 'signature', 'w'), positions.dig('page_2', 'signature', 'h')]
  end
  # Width and Height to fit the signature within. Currently:
  #
  def driver_sig_fit
    @driver_sig_fit ||= [positions.dig('page_2', 'driver_signature', 'w'), positions.dig('page_2', 'driver_signature', 'h')]
  end

  def signature_content
    params.dig('signature', 'content')
  end

  def driver_sig_content
    params.dig('driver_signature', 'content')
  end

  def signature_url
    params.dig('signature', 'url')
  end

  def driver_sig_url
    params.dig('driver_signature', 'url')
  end

  def signature_path
    path.join('signature.png')
  end

  def driver_sig_path
    path.join('driver_signature.png')
  end

  def pdf
    @pdf ||= new_pdf
  end

  def new_pdf
    Prawn::Document.new(:page_size => 'LETTER')
  end

  # The full list of AM/PM boxes across all pages
  # Makes it easier to retrieve them from the stroke method above
  #
  def am_pm_positions
    @am_pm_positions ||= page_1_am_pm.merge(page_2_am_pm)
  end

  def page_1_am_pm
    @page_1_am_pm ||= positions.dig('page_1', 'am_pm')
  end

  def page_2_am_pm
    @page_2_am_pm ||= positions.dig('page_2', 'am_pm')
  end


  #
  # Coordinates extracted using the python script in the utilities folder
  # TODO: We should actually be able to read these positions out of the PDF document so they don't need to be passed in.
  #
  def positions
    @postitions ||= JSON.parse(position_file)
  end

  def position_file
    File.read(Pathname.new(File.dirname(File.expand_path(__FILE__))).join('assets', 'overlay_positions.json'))
  end

  class OverlayError < StandardError
  end

end