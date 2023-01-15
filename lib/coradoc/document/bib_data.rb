module Coradoc
  module Document
    class BibData
      ATTRIBUTES = [
        :docnumber,
        :tc_docnumber,
        :partnumber,
        :edition,
        :revdate,
        :copyright_year,
        :language,
        :title_intro_en,
        :title_main_en,
        :title_part_en,
        :title_intro_fr,
        :title_main_fr,
        :title_part_fr,
        :doctype,
        :docstage,
        :docsubstage,
        :draft,
        :technical_committee_number,
        :secretariat,
        :technical_committee,
        :subcommittee_number,
        :subcommittee,
        :workgroup_type,
        :workgroup_number,
        :workgroup,
        :library_ics,
        :mn_document_class,
        :mn_output_extensions,
        :local_cache_only,
      ]

      attr_reader *ATTRIBUTES

      def initialize(attributes)
        slice_bibdata_attributes(attributes)
      end

      private

      attr_writer *ATTRIBUTES

      def slice_bibdata_attributes(attributes)
        ATTRIBUTES.each do |attr|
          value = attributes[attr.to_s] || attributes[attr.to_s.gsub("_", "-")]
          self.send("#{attr}=", value)
        end
      end
    end
  end
end
