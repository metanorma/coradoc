require "fileutils"
require "pathname"
require "tempfile"
require "base64"
require "marcel"

module Coradoc
  module Input
    module Html
      module Converters
        class Img < Base
          def image_number
            sprintf(
              Coradoc::Input::Html.config.image_counter_pattern,
              Coradoc::Input::Html.config.image_counter,
            )
          end

          def image_number_increment
            Coradoc::Input::Html.config.image_counter += 1
          end

          def datauri2file(src)
            return unless src

            %r{^data:image/(?:[^;]+);base64,(?<imgdata>.+)$} =~ src

            dest_dir = Pathname.new(Coradoc::Input::Html.config.destination).dirname
            images_dir = dest_dir.join("images")
            FileUtils.mkdir_p(images_dir)

            ext, image_src_path, tempfile = determine_image_src_path(src,
                                                                     imgdata)
            image_dest_path = images_dir + "#{image_number}.#{ext}"

            # puts "image_dest_path: #{image_dest_path.to_s}"
            # puts "image_src_path: #{image_src_path.to_s}"

            if File.exist?(image_src_path)
              FileUtils.cp(image_src_path, image_dest_path)
            else
              @annotate_missing = image_src_path
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
            [ext, Pathname.new(Coradoc::Input::Html.config.sourcedir).join(src)]
          end

          def copy_temp_file(imgdata)
            f = Tempfile.open(["radoc", ".jpg"])
            f.binmode
            f.write(Base64.strict_decode64(imgdata))
            f.rewind
            ext = Marcel::MimeType.for(f).sub(%r{^[^/]+/}, "")
            ext = "svg" if ext == "svg+xml"
            [ext, f.path, f]
          end

          def to_coradoc(node, _state = {})
            id = node["id"]
            alt   = node["alt"]
            src   = node["src"]
            width = node["width"]
            height = node["height"]

            width = width.to_i if width&.match?(/\A\d+\z/)
            height = height.to_i if height&.match?(/\A\d+\z/)

            title = extract_title(node)

            if Coradoc::Input::Html.config.external_images
              # puts "external image conversion #{id}, #{src}"
              src = datauri2file(src)
            end

            attributes = Coradoc::Element::AttributeList.new
            # attributes.add_named("id", id) if id
            if alt # && !alt.to_s.empty?
              attributes.add_positional(alt)
            elsif width || height
              attributes.add_positional(nil)
            end
            attributes.add_named("title", title) if title && !title.empty?
            attributes.add_positional(width) if width
            attributes.add_positional(height) if height

            if src
              Coradoc::Element::Image::BlockImage.new(
                title:, id:, src:, attributes: attributes,
                annotate_missing: @annotate_missing)
            end
          end
        end

        register :img, Img
      end
    end
  end
end
