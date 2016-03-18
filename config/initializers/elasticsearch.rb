# if the indexes do not exist, create it!
# if Dataset.__elasticsearch__.index_exists?
#   Dataset.__elasticsearch__.delete_index!
#   Dataset.__elasticsearch__.client.indices.delete index: Dataset.index_name rescue nil
#   puts "delete"
# end
unless Dataset.__elasticsearch__.index_exists?
  puts "!! Dataset elasticsearch index does not exist - creating !!"
  #Dataset.__elasticsearch__.create_index! force: true
  Dataset.__elasticsearch__.client.indices.create index: Dataset.index_name,
    body: {
      settings: {
        analysis: {
          analyzer: {
            standard_without_html: {
              tokenizer: "standard",
              char_filter:  "html_strip",
              filter:  [ "lowercase" ]
            }
          }
        }
      },
      mappings: {
        Dataset.document_type => {
          dynamic_templates:
          [
            {
              localize_fields_title:
              {
                match_mapping_type: "string|date|boolean|double|long|integer",
                match_pattern: "regex",
                path_match: "titles.*",
                mapping:
                {
                  type: "multi_field",
                  fields: {
                    "{name}" => { type: 'string', analyzer: "standard" },
                    raw: { type: 'string', index: "not_analyzed" }
                  }
                }
              }
            },
            {
              localize_fields_without_html:
              {
                match_mapping_type: "string|date|boolean|double|long|integer",
                match_pattern: "regex",
                path_match: "(descriptions|methodologies).*",
                mapping:
                {
                  type: "string",
                  analyzer: "standard_without_html"
                }
              }
            },
            {
              localize_fields:
              {
                match_mapping_type: "string|date|boolean|double|long|integer",
                match_pattern: "regex",
                path_match: "(sources|donors).*",
                mapping:
                {
                  type: "string",
                  index: "not_analyzed"
                }
              }
            }
          ],
          properties: {
            titles: {
              type: "object"
            },
            descriptions: {
              type: "object"
            },
            methodologies: {
              type: "object"
            },
            sources: {
              type: "object"
            },
            donors: {
              type: "object"
            },
            "public" => {
              type: "boolean",
              index: "not_analyzed"
            },
            public_at: {
              type: "date",
              index: "not_analyzed"
            },
            released_at: {
              type: "date",
              index: "not_analyzed"
            }
          }
        }
      }
    }
  Dataset.import return: 'errors' # force: true
end

unless TimeSeries.__elasticsearch__.index_exists?
  puts "!! TimeSeries elasticsearch index does not exist - creating !!"
  #TimeSeries.__elasticsearch__.create_index! force: true
  TimeSeries.__elasticsearch__.client.indices.create index: TimeSeries.index_name,
    body: {
      settings: {
        analysis: {
          analyzer: {
            standard_without_html: {
              tokenizer: "standard",
              char_filter:  "html_strip",
              filter:  [ "lowercase" ]
            }
          }
        }
      },
      mappings: {
        TimeSeries.document_type => {
          dynamic_templates:
          [
            {
              localize_fields_title:
              {
                match_mapping_type: "string|date|boolean|double|long|integer",
                match_pattern: "regex",
                path_match: "titles.*",
                mapping:
                {
                  type: "multi_field",
                  fields: {
                    "{name}" => { type: 'string', analyzer: "standard" },
                    raw: { type: 'string', index: "not_analyzed" }
                  }
                }
              }
            },
            {
              localize_fields_without_html:
              {
                match_mapping_type: "string|date|boolean|double|long|integer",
                match_pattern: "regex",
                path_match: "descriptions.*",
                mapping:
                {
                  type: "string",
                  analyzer: "standard_without_html"
                }
              }
            }
          ],
          properties: {
            titles: {
              type: "object"
            },
            descriptions: {
              type: "object"
            },
            sources: {
              type: "object"
            },
            donors: {
              type: "object"
            },
            "public" => {
              type: "boolean",
              index: "not_analyzed"
            },
            public_at: {
              type: "date",
              index: "not_analyzed"
            }
          }
        }
      }
    }
  TimeSeries.import return: 'errors'
end
