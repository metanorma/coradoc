# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'tempfile'
require 'base64'
require 'marcel'

module Coradoc
  module Html
    module Converters
      class Img < Base
        INSTANCE = new

        def image_number
          format(
            Html.input_config.image_counter_pattern,
            Html.input_config.image_counter
          )
        end

        def image_number_increment
          Html.input_config.image_counter += 1
        end

        def datauri2file(src)
          return unless src

          %r{^data:image/(?:[^;]+);base64,(?<imgdata>.+)$} =~ src

          dest_dir = Pathname.new(Html.input_config.destination).dirname
          images_dir = dest_dir.join('images')
          FileUtils.mkdir_p(images_dir)

          ext, image_src_path, tempfile = determine_image_src_path(
            src,
            imgdata
          )
          image_dest_path = images_dir + "#{image_number}.#{ext}"

          if File.exist?(image_src_path)
            FileUtils.cp(image_src_path, image_dest_path)
          else
            Kernel.warn "Image #{image_src_path} does not exist"
          end

          image_number_increment

          image_dest_path.relative_path_from(dest_dir)
        ensure
          tempfile&.close!
        end

        def determine_image_src_path(src, imgdata)
          return copy_temp_file(imgdata) if imgdata

          ext = File.extname(src).strip.downcase[1..]
          [ext, Pathname.new(Html.input_config.sourcedir).join(src)]
        end

        def copy_temp_file(imgdata)
          f = Tempfile.open(['radoc', '.jpg'])
          f.binmode
          f.write(Base64.strict_decode64(imgdata))
          f.rewind
          ext = Marcel::MimeType.for(f).sub(%r{^[^/]+/}, '')
          ext = 'svg' if ext == 'svg+xml'
          [ext, f.path, f]
        end

        def to_coradoc(node, _state = {})
          id = node['id']
          alt   = node['alt']
          src   = node['src']
          width = node['width']
          height = node['height']

          # Convert width/height to integers if they are numeric strings
          width = width.to_i if width&.match?(/\A\d+\z/)
          height = height.to_i if height&.match?(/\A\d+\z/)

          title = extract_title(node)

          src = datauri2file(src) if Html.input_config.external_images

          # Use CoreModel::Image
          return unless src

          Coradoc::CoreModel::Image.new(
            src: src,
            alt: alt,
            caption: title,
            width: width&.to_s,
            height: height&.to_s,
            id: id
          )
        end
      end

      register :img, Img::INSTANCE
    end
  end
end
