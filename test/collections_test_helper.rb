require_relative "./test_helper"

VALID_COLLECTION_METADATA_KEYS = %w[collection created_by display_name image items].freeze
REQUIRED_COLLECTION_METADATA_KEYS = %w[items display_name].freeze

MAX_COLLECTION_ITEMS_LENGTH = 100
MAX_COLLECTION_SLUG_LENGTH = 40
MAX_COLLECTION_DISPLAY_NAME_LENGTH = 100

COLLECTION_IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif].freeze
COLLECTION_REGEX = /\A[a-z0-9][a-z0-9-]*\Z/

USERNAME_REGEX = /\A[a-z0-9]+(-[a-z0-9]+)*\z/i
USERNAME_AND_REPO_REGEX = %r{\A[^/]+/[^/]+$\z}

def invalid_collection_message(collection)
  "'#{collection}' must be between 1-#{MAX_COLLECTION_SLUG_LENGTH} characters, " \
  "start with a letter or number, and may include hyphens"
end

def valid_collection?(raw_collection)
  return false unless raw_collection

  collection = raw_collection.strip
  return false if collection.length > MAX_COLLECTION_SLUG_LENGTH
  return false unless collection.match?(COLLECTION_REGEX)

  !collection.empty?
end

def collections_dir
  File.expand_path("../collections", File.dirname(__FILE__))
end

def collection_dirs
  Dir["#{collections_dir}/*"].select do |entry|
    entry != "." && entry != ".." && File.directory?(entry)
  end
end

def collections
  collection_dirs.map { |dir_path| File.basename(dir_path) }
end

def items_for_collection(collection)
  metadata = metadata_for(collections_dir, collection) || {}
  metadata["items"]
end

def image_paths_for_collection(collection)
  Dir["#{collections_dir}/#{collection}/*"].select do |entry|
    File.file?(entry) && COLLECTION_IMAGE_EXTENSIONS.include?(File.extname(entry).downcase)
  end
end

def update_collection_item(collection, old_repo_with_owner, new_repo_with_owner)
  file = "#{collections_dir}/#{collection}/index.md"

  File.open(file, "r+") do |f|
    new_content = f.read.gsub(old_repo_with_owner, new_repo_with_owner)
    f.rewind
    f.write(new_content)
    f.truncate(f.pos)
  end
end

def annotate_collection_item_error(collection, string, error_message)
  file = "#{collections_dir}/#{collection}/index.md"

  line_number = File.open(file, "r") do |f|
    file_contents = f.readlines
    string == "" ? 1 : file_contents.index { |line| line.include?(string) } + 1
  end

  add_message("error", "collections/#{collection}/index.md", line_number, error_message)
end

def possible_image_file_names_for_collection(collection)
  COLLECTION_IMAGE_EXTENSIONS.map { |ext| "#{collection}#{ext}" }
end
